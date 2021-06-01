# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Version

=begin

Returns version number of application

  version = Version.get

returns

  '1.3.0' # example

=end

  def self.get
    File.read(Rails.root.join('VERSION')).strip
  rescue => e
    Rails.logger.error "VERSION file could not be read: #{e}"
    ''
  end
end
