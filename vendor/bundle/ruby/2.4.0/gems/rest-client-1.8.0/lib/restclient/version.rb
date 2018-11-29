module RestClient
  VERSION = '1.8.0' unless defined?(self::VERSION)

  def self.version
    VERSION
  end
end
