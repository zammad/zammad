# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class UserDevice < ApplicationModel
  store     :device_details
  store     :location_details
  validates :name, presence: true

=begin

store new device for user if device not already known

  user_device = UserDevice.add(
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
    '172.0.0.1',
    user.id,
    'fingerprintABC123',
    'session', # session|basic_auth|token_auth|sso
  )

=end

  def self.add(user_agent, ip, user_id, fingerprint, type)

    # since gem browser 2 is not handling nil for user_agent, set it to ''
    if user_agent.nil?
      user_agent = ''
    end

    # get location info
    location_details = Service::GeoIp.location(ip)
    location = 'unknown'
    if location_details
      location = location_details['country_name']
    end

    # find device by fingerprint
    device_exists_by_fingerprint = false
    if fingerprint
      user_devices = UserDevice.where(
        user_id: user_id,
        fingerprint: fingerprint,
      )
      user_devices.each {|local_user_device|
        device_exists_by_fingerprint = true
        next if local_user_device.location != location
        return action(local_user_device.id, user_agent, ip, user_id) if local_user_device
      }
    end

    # for basic_auth|token_auth search for user agent
    if type == 'basic_auth' || type == 'token_auth'
      user_device = UserDevice.find_by(
        user_id: user_id,
        user_agent: user_agent,
        location: location,
      )
      return action(user_device.id, user_agent, ip, user_id) if user_device
    end

    # get browser details
    browser = Browser.new(user_agent, accept_language: 'en-us')
    browser = {
      plattform: browser.platform.to_s.camelize,
      name: browser.name,
      version: browser.version,
      full_version: browser.full_version,
    }

    # generate device name
    if browser[:name] == 'Generic Browser'
      browser[:name] = user_agent
    end
    name = ''
    if browser[:plattform] && browser[:plattform] != 'Other'
      name = browser[:plattform]
    end
    if browser[:name] && browser[:name] != 'Other'
      if name && !name.empty?
        name += ', '
      end
      name += browser[:name]
    end

    # if not identified, use user agent
    if !name || name == '' || name == 'Other, Other' || name == 'Other'
      name = user_agent
      browser[:name] = user_agent
    end

    # check if exists
    user_device = find_by(
      user_id: user_id,
      os: browser[:plattform],
      browser: browser[:name],
      location: location,
      fingerprint: fingerprint,
    )

    if user_device
      return action(user_device.id, user_agent, ip, user_id) if user_device
    end

    # create new device
    user_device = create(
      user_id: user_id,
      name: name,
      os: browser[:plattform],
      browser: browser[:name],
      location: location,
      device_details: browser,
      location_details: location_details,
      user_agent: user_agent,
      ip: ip,
      fingerprint: fingerprint,
    )

    # send notification if needed
    user_devices = UserDevice.where(user_id: user_id).count
    if user_devices >= 2

      # notify on now device of if country has changed
      if device_exists_by_fingerprint
        user_device.notification_send('user_device_new_location')
      else
        user_device.notification_send('user_device_new')
      end
    end

    user_device
  end

=begin

log user device action

  UserDevice.action(
    user_device_id,
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
    '172.0.0.1',
    user.id,
  )

=end

  def self.action(user_device_id, user_agent, ip, user_id)
    user_device = UserDevice.find(user_device_id)

    # update location if needed
    if user_device.ip != ip
      user_device.ip = ip
      location_details = Service::GeoIp.location(ip)
      user_device.location_details = location_details

      location = location_details['country_name']

      # notify if country has changed
      if user_device.location != location
        return UserDevice.add(
          user_agent,
          ip,
          user_id,
          user_device.fingerprint,
          'session',
        )
      end
    end

    # update attributes
    user_device.updated_at = Time.zone.now # force update, also if no other attribute has changed
    user_device.save
    user_device
  end

=begin

send user notification about new device or new location for device

  user_device = UserDevice.find(id)

  user_device.notification_send('user_device_new_location')

=end

  def notification_send(template)
    user = User.find(user_id)

    NotificationFactory.notification(
      template: template,
      user: user,
      objects: {
        user_device: self,
        user: user,
      }
    )
  end

end
