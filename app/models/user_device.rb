# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class UserDevice < ApplicationModel
  store     :device_details
  store     :location_details
  validates :name, presence: true

=begin

store device for user

  UserDevice.add(
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
    '172.0.0.1',
    user.id,
  )

=end

  def self.add(user_agent, ip, user_id)

    # get browser details
    browser = Browser.new(:ua => user_agent, :accept_language => 'en-us')
    browser = {
      plattform: browser.platform.to_s.camelize,
      name: browser.name,
      version: browser.version,
      full_version: browser.full_version,
    }

    # generate device name
    name = browser[:plattform] || ''
    if browser[:name]
      if name
        name += ', '
      end
      name += browser[:name]
    end

    # get location info
    location = Service::GeoIp.location(ip)
    country = location['country_name']

    # check if exists
    exists = self.find_by(
      :user_id => user_id,
      os: browser[:plattform],
      browser: browser[:name],
      location: country,
    )

    if exists
      exists.touch
      return exists
    end

    # create new device
    self.create(
      user_id: user_id,
      name: name,
      os: browser[:plattform],
      browser: browser[:name],
      location: country,
      device_details: browser,
      location_details: location,
    )
  end

end
