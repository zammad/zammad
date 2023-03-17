# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Version

=begin

Returns version number of application

  version = Version.get

returns

  '1.3.0' # example

=end

  def self.get
    Rails.root.join('VERSION').read.strip
  rescue => e
    Rails.logger.error "VERSION file could not be read: #{e}"
    ''
  end
end
