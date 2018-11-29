# frozen_string_literal: true
module Mail
  module VERSION

    MAJOR = 2
    MINOR = 7
    PATCH = 1
    BUILD = 'rc1'

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')

    def self.version
      STRING
    end

  end
end
