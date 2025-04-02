# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AppVersion

  MAINTENANCE_THREAD_SLEEP   = 5.seconds
  REDIS_RESTART_REQUIRED_KEY = 'zammad_restart_required_timestamp'.freeze
  REDIS_RESTART_REQUIRED_TTL = 5.minutes

  MSG_APP_VERSION    = 'app_version'.freeze
  MSG_RESTART_MANUAL = 'restart_manual'.freeze
  MSG_RESTART_AUTO   = 'restart_auto'.freeze
  MSG_CONFIG_CHANGED = 'config_changed'.freeze

  class_attribute :_redis

=begin

get current app version

  version = AppVersion.get

returns

  '20150212131700:0' # 'version:if_browser_reload_is_required'

=end

  def self.get
    Setting.get('app_version')
  end

  def self.trigger_browser_reload(type, timestamp: make_timestamp)
    return if !Setting.exists?(name: 'app_version')

    Setting.set('app_version', timestamp)
    Sessions.broadcast(event_data(type), 'public')
    Gql::Subscriptions::AppMaintenance.trigger({ type: type })
  end

  def self.trigger_restart
    timestamp = make_timestamp

    type = if Setting.get('auto_shutdown')
             restart_required!(timestamp)
             MSG_RESTART_AUTO
           else
             MSG_RESTART_MANUAL
           end

    trigger_browser_reload(type, timestamp:)
  end

  def self.start_maintenance_thread(process_name:)
    return if !Setting.get('auto_shutdown')

    initial_app_version = get

    Rails.logger.debug { "Starting maintenance thread for #{process_name} (#{Process.pid})" }
    Thread.new do
      Thread.current.abort_on_exception = true
      Thread.current.name = 'app version monitoring'

      loop do
        if restart_required?(initial_app_version)
          Rails.logger.debug { "App version change detected, sending TERM signal to #{process_name} (#{Process.pid})" }
          Process.kill('TERM', Process.pid)
          break
        end

        sleep MAINTENANCE_THREAD_SLEEP
      end
    end
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

  def self.make_timestamp
    Time.current.strftime('%Y%m%d%H%M%S')
  end
  private_class_method :make_timestamp

  def self.restart_required!(timestamp)
    redis.set(REDIS_RESTART_REQUIRED_KEY, timestamp, ex: REDIS_RESTART_REQUIRED_TTL)
  end
  private_class_method :restart_required!

  def self.restart_required?(known_app_version)
    value = redis.get(REDIS_RESTART_REQUIRED_KEY)

    value.present? && (known_app_version != value)
  end
  private_class_method :restart_required?

  def self.redis
    self._redis ||= Zammad::Service::Redis.new
  end
  private_class_method :redis
end
