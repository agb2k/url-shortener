# frozen_string_literal: true

class Base62Encoder
  CHARSET = ("0".."9").to_a.concat(("a".."z").to_a).concat(("A".."Z").to_a).join.freeze
  BASE = 62
  MAX_LENGTH = 15 # Keeps short codes small and within index-friendly length.

  class << self
    def encode(id)
      return CHARSET[0] if id.nil? || id < 0
      return CHARSET[0] if id.zero?

      s = +""
      n = id.to_i
      while n.positive?
        s.prepend(CHARSET[n % BASE])
        n /= BASE
      end
      s.length > MAX_LENGTH ? s[-MAX_LENGTH, MAX_LENGTH] : s
    end
  end
end
