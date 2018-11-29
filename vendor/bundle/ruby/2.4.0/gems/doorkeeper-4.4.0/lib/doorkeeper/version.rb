module Doorkeeper
  CVE_2018_1000211_WARNING = <<-HEREDOC.freeze


  WARNING: This is a security release that addresses token revocation not working for public apps (CVE-2018-1000211)

  There is no breaking change in this release, however to take advantage of the security fix you must:

    1. Run `rails generate doorkeeper:add_client_confidentiality` for the migration
    2. Review your OAuth apps and determine which ones exclusively use public grant flows (eg implicit)
    3. Update their `confidential` column to `false` for those public apps

  This is a backported security release.

  For more information:

    * https://github.com/doorkeeper-gem/doorkeeper/pull/1119
    * https://github.com/doorkeeper-gem/doorkeeper/issues/891


HEREDOC

  def self.gem_version
    Gem::Version.new VERSION::STRING
  end

  module VERSION
    # Semantic versioning
    MAJOR = 4
    MINOR = 4
    TINY = 0

    # Full version number
    STRING = [MAJOR, MINOR, TINY].compact.join('.')
  end
end
