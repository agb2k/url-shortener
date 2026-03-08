# Primary (Postgres) is the source of truth for application data: transactional, durable,
# and suitable for CRUD and consistency (e.g. ShortLink).
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
