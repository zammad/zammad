# Copyright (C) 2012-2017 Zammad Foundation, http://zammad-foundation.org/

class Version

=begin

Returns version number of application

  version = Version.get

returns

  '1.3.0' # example

=end

  def self.get

    begin
      version = File.read("#{Rails.root}/VERSION")
      version.strip!
    rescue => e
      message = e.to_s
      Rails.logger.error "VERSION file could not be read: #{message}"

      version = ''
    end

    version
  end

end
