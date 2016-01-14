# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class UserDevice < ApplicationModel
  store     :device_details
  store     :location_details
  validates :name, presence: true

=begin

store device for user

  user_device = UserDevice.add(
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
    '172.0.0.1',
    user.id,
    'fingerprintABC123',
    'session', # session|basic_auth|token_auth|sso
  )

=end

  def self.add(user_agent, ip, user_id, fingerprint, type)

    # get location info
    location_details = Service::GeoIp.location(ip)
    location = 'unknown'
    if location_details
      location = location_details['country_name']
    end

    # find device by fingerprint
    if fingerprint
      user_device = UserDevice.find_by(
        user_id: user_id,
        fingerprint: fingerprint,
        location: location,
      )
      return action(user_device.id, user_agent, ip, user_id) if user_device
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
    browser = Browser.new(ua: user_agent, accept_language: 'en-us')
    browser = {
      plattform: browser.platform.to_s.camelize,
      name: browser.name,
      version: browser.version,
      full_version: browser.full_version,
    }

    # generate device name
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
      user_device.send_notification
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

  def self.action(user_device_id, _user_agent, ip, _user_id)
    user_device = UserDevice.find(user_device_id)

    # update location if needed
    if user_device.ip != ip
      user_device.ip = ip
      location_details = Service::GeoIp.location(ip)
      user_device.location_details = location_details

      location = location_details['country_name']
      user_device.location = location
    end

    # update attributes
    user_device.save
    user_device
  end

=begin

send new user device info

  user_device = UserDevice.find(id)

  user_device.send_notification

=end

  def send_notification
    user = User.find(user_id)

    # send mail
    data = {}
    data[:subject] = '#{config.product_name} signin detected from a new device'
    data[:body]    = 'Hi #{user.firstname},

it looks like you signed into your #{config.product_name} account using a new device on "#{user_device.created_at}":

Your Location: #{user_device.location}
Your IP: #{user_device.ip}

Your device has been added to your list of known devices, which you can view here:

#{config.http_type}://#{config.fqdn}/#profile/devices

If this wasn\'t you, remove the device, changing your account password, and contacting your administrator. Somebody might have gained unauthorized access to your account.

Your #{config.product_name} Team'

    # prepare subject & body
    [:subject, :body].each { |key|
      data[key.to_sym] = NotificationFactory.build(
        locale: user.preferences[:locale],
        string: data[key.to_sym],
        objects: {
          user_device: self,
          user: user,
        }
      )
    }

    # send notification
    NotificationFactory.send(
      recipient: user,
      subject: data[:subject],
      body: data[:body]
    )
  end
end
