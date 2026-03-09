# URL Shortener

Paste a long URL, get a short link. Every click is tracked with country and timestamp.

**Live app:** [https://short-url-agb2k.duckdns.org](https://short-url-agb2k.duckdns.org)

---

## Stack

Ruby on Rails, PostgreSQL, ClickHouse, Redis, Tailwind CSS, Docker, AWS EC2, Caddy.

**PostgreSQL** stores short links. **ClickHouse** stores visit events (one row per click) — kept separate because it's much faster for aggregations. **Redis** caches redirect lookups and handles rate limiting. **Solid Queue** runs background jobs (title scraping, visit logging) inside the web process so they don't block requests.

In production, everything runs on a single EC2 instance (t3.small) via Docker Compose. Caddy handles HTTPS automatically. Pushing to `main` triggers a GitHub Actions workflow that redeploys the server over SSH.

---

## Main Flows

**Create:** URL is normalised (scheme added, `www.` stripped, trailing slash removed) so duplicates are caught. A random 7-character code is generated and saved. Title is fetched in the background and pushed to the page via Turbo Streams. The create endpoint also accepts and returns JSON, so it can be used as an API without the UI.

**Redirect:** Redis is checked first. On a hit, the visitor is redirected immediately. On a miss, Postgres is queried, the result cached for 24 hours, then the visitor is redirected. The visit is logged to ClickHouse in the background.

**Stats:** Two ClickHouse aggregations (clicks per link, clicks per country) are joined with Postgres short link records and rendered as a sorted table.

---

## Code Map

| What | File |
|---|---|
| Routes | [config/routes.rb](config/routes.rb) |
| Create, show, redirect | [app/controllers/short_links_controller.rb](app/controllers/short_links_controller.rb) |
| Short link model | [app/models/short_link.rb](app/models/short_link.rb) |
| Redirect cache | [app/services/short_link_redirect_resolver.rb](app/services/short_link_redirect_resolver.rb) |
| Rate limiting | [app/services/rate_limiter.rb](app/services/rate_limiter.rb) |
| Stats query | [app/services/visit_stats_query.rb](app/services/visit_stats_query.rb) |
| Visit model | [app/models/visit.rb](app/models/visit.rb) |
| Display logic | [app/presenters/short_link_presenter.rb](app/presenters/short_link_presenter.rb) |
| Title scraping | [app/jobs/scrape_title_job.rb](app/jobs/scrape_title_job.rb) |
| Visit logging | [app/jobs/log_visit_job.rb](app/jobs/log_visit_job.rb) |

---

## Running Locally

**Prerequisites:** Ruby (see [.ruby-version](.ruby-version)), Docker.

```bash
bundle install
docker compose up -d              # Postgres, ClickHouse, Redis
bin/rails db:prepare
bin/rails db:migrate:analytics
bin/dev                           # http://localhost:3000
```

Optionally add to `.env` (see [.env.example](.env.example)) to enable Redis:
```
REDIS_URL=redis://localhost:6379/0
```

```bash
bin/rails test   # run tests
```

---

## Deployment

Traffic flows: `Visitor -> Caddy (HTTPS) -> Rails (port 3000) -> Postgres / ClickHouse / Redis`

Hosted on AWS EC2 (t3.small, Amazon Linux 2023). Caddy handles TLS via Let's Encrypt. Domain is a free [DuckDNS](https://www.duckdns.org) subdomain. CI/CD via GitHub Actions on push to `main`.

The CI pipeline runs on every push and pull request: static security analysis (Brakeman), dependency vulnerability scanning (bundler-audit), linting (RuboCop), and the full test suite.

**First-time server setup:**
```bash
git clone https://github.com/agb2k/url-shortener.git
cp env.production.example .env.production
docker compose -f docker-compose.production.yml up -d --build
docker compose -f docker-compose.production.yml exec web bin/rails db:migrate
docker compose -f docker-compose.production.yml exec web bin/rails db:migrate:analytics
```

---

## Decisions and Trade-offs

| Decision | Why | Downside |
|---|---|---|
| Random short codes over sequential IDs | Sequential IDs are predictable and anyone can increment through them to enumerate all links. Random codes prevent that. 62^7 is ~3.5 billion combinations | Small uniqueness check on every create |
| ClickHouse for visit data | Faster at aggregations, keeps analytics load off Postgres | Two databases to run |
| Redis is optional | App works without it locally, degrading gracefully | Caching and rate limiting only active when Redis is set |
| Solid Queue in web process | No separate worker to manage | Background job spikes could affect web latency |
| URL normalisation | `google.com` and `https://www.google.com` map to one link | `http` and `https` versions also map to the same link |

---

## Scalability and Security

**Scalability:** Redis caches each redirect for 24 hours so Postgres is only hit once per link per day. ClickHouse handles write-heavy visit data separately. The web layer is stateless so horizontal scaling works without code changes. Token length can be increased from 7 to 8 characters to expand code space from 3.5B to 218B if needed.

**Security:** Rate limited to 10 creates per IP per minute (429 + `Retry-After`). Title scraping only follows `http`/`https` URLs to prevent internal network probing. The app rejects URLs pointing at its own domain. CSRF tokens on all forms. HTTPS enforced via Caddy. Secrets stored in environment variables, never in the repo.
