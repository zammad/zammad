# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  MSG_APP_VERSION    = 'app_version'.freeze
  MSG_RESTART_MANUAL = 'restart_manual'.freeze
  MSG_RESTART_AUTO   = 'restart_auto'.freeze
  MSG_CONFIG_CHANGED = 'config_changed'.freeze

=begin

set new app version and if browser reload is required

  AppVersion.set(true) # true == reload is required / false == no reload is required

send also reload type to clients

  AppVersion.set(true, AppVersion::MSG_APP_VERSION)     # -> new app version
  AppVersion.set(true, AppVersion::MSG_RESTART_MANUAL)  # -> app needs restart
  AppVersion.set(true, AppVersion::MSG_RESTART_AUTO)    # -> app is restarting
  AppVersion.set(true, AppVersion::MSG_CONFIG_CHANGED)  # -> config has changed

=end

  def self.set(reload_required = false, type = MSG_APP_VERSION)
    return false if !Setting.exists?(name: 'app_version')

    version = "#{Time.zone.now.strftime('%Y%m%d%H%M%S')}:#{reload_required}"
    Setting.set('app_version', version)

    # broadcast to clients
    Sessions.broadcast(event_data(type), 'public')

    Gql::Subscriptions::AppMaintenance.trigger({ type: type })
  end

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
