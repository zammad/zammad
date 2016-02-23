# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class AppVersion

=begin

get current app version

  version = AppVersion.get

returns

  '20150212131700:0' # 'version:if_browser_reload_is_required'

=end

  def self.get
    Setting.get('app_version')
  end

=begin

set new app version and if browser reload is required

  AppVersion.set(true) # true == reload is required / false == no reload is required

=end

  def self.set(reload_required = false)
    version = "#{Time.zone.now.strftime('%Y%m%d%H%M%S')}:#{reload_required}"
    Setting.set('app_version', version)

    # broadcast to clients
    Sessions.broadcast(event_data)
  end

=begin

get event data

  AppVersion.event_data

returnes

  {
    event: 'app_version'
    data: {
      app_version: app_version,
    }
  }

=end

  def self.event_data
    {
      event: 'app_version',
      data: {
        app_version: get,
      }
    }
  end

end
