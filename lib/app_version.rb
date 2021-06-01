# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

send also reload type to clients

  AppVersion.set(true, 'app_version')
  AppVersion.set(true, 'restart_manual')
  AppVersion.set(true, 'restart_auto')
  AppVersion.set(true, 'config_changed')

=end

  def self.set(reload_required = false, type = 'app_version')
    return false if !Setting.exists?(name: 'app_version')

    version = "#{Time.zone.now.strftime('%Y%m%d%H%M%S')}:#{reload_required}"
    Setting.set('app_version', version)

    # broadcast to clients
    Sessions.broadcast(event_data(type), 'public')
  end

=begin

get event data

  AppVersion.event_data(type)

types:

  app_version -> new app version
  restart_manual -> app needs restart
  restart_auto -> app is restarting
  config_changed -> config has changed

returns

  {
    event: 'maintenance'
    data: {
      type: 'app_version',
      app_version: app_version,
    }
  }

=end

  def self.event_data(type = 'app_version')
    {
      event: 'maintenance',
      data:  {
        type:        type,
        app_version: get,
      }
    }
  end

end
