# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Setting < ApplicationModel
  store         :options
  store         :state_current
  store         :state_initial
  store         :preferences
  before_create :state_check, :set_initial
  before_update :state_check
  after_create  :reset_cache
  after_update  :reset_cache
  after_destroy :reset_cache

  attr_accessor :state

  @@current        = {} # rubocop:disable Style/ClassVars
  @@change_id      = nil # rubocop:disable Style/ClassVars
  @@lookup_at      = nil # rubocop:disable Style/ClassVars
  if ENV['ZAMMAD_SETTING_TTL']
    @@lookup_timeout = ENV['ZAMMAD_SETTING_TTL'].to_i.seconds # rubocop:disable Style/ClassVars
  else
    @@lookup_timeout = 2.minutes # rubocop:disable Style/ClassVars
  end

=begin

set config setting

  Setting.set('some_config_name', some_value)

=end

  def self.set(name, value)
    setting = Setting.find_by( name: name )
    if !setting
      fail "Can't find config setting '#{name}'"
    end
    setting.state_current = { value: value }
    setting.save
    logger.info "Setting.set(#{name}, #{value.inspect})"
  end

=begin

get config setting

  value = Setting.get('some_config_name')

=end

  def self.get(name)
    if load
      logger.debug "Setting.get(#{name.inspect}) # no cache"
    else
      logger.debug "Setting.get(#{name.inspect}) # from cache"
    end
    @@current[:settings_config][name]
  end

=begin

reset config setting to default

  Setting.reset('some_config_name')

=end

  def self.reset(name)
    setting = Setting.find_by( name: name )
    if !setting
      fail "Can't find config setting '#{name}'"
    end
    setting.state_current = setting.state_initial
    setting.save
    logger.info "Setting.reset(#{name}, #{setting.state_current.inspect})"
    load
    @@current[:settings_config][name]
  end

  private

  # load values and cache them
  def self.load

    # check if config is already generated
    if @@current[:settings_config]
      return false if cache_valid?
    end

    # read all config settings
    config = {}
    Setting.select('name, state_current').order(:id).each { |setting|
      config[setting.name] = setting.state_current[:value]
    }

    # config lookups
    config.each { |key, value|
      next if value.class.to_s != 'String'

      config[key].gsub!( /\#\{config\.(.+?)\}/ ) {
        config[$1].to_s
      }
    }

    # store for class requests
    cache(config)
    true
  end

  # set initial value in state_initial
  def set_initial
    self.state_initial = state_current
  end

  # set new cache
  def self.cache(config)
    @@change_id = Cache.get('Setting::ChangeId') # rubocop:disable Style/ClassVars
    @@current[:settings_config] = config
    logger.debug "Setting.cache: set cache, #{@@change_id}"
    @@lookup_at = Time.zone.now # rubocop:disable Style/ClassVars
  end

  # reset cache
  def reset_cache
    @@change_id = rand(999_999_999).to_s # rubocop:disable Style/ClassVars
    logger.debug "Setting.reset_cache: set new cache, #{@@change_id}"

    Cache.write('Setting::ChangeId', @@change_id, { expires_in: 24.hours })
    @@current[:settings_config] = nil
  end

  # check if cache is still valid
  def self.cache_valid?
    if @@lookup_at && @@lookup_at > Time.zone.now - @@lookup_timeout
      #logger.debug 'Setting.cache_valid?: cache_id has beed set within last 2 minutes'
      return true
    end
    change_id = Cache.get('Setting::ChangeId')
    if change_id == @@change_id
      @@lookup_at = Time.zone.now # rubocop:disable Style/ClassVars
      logger.debug "Setting.cache_valid?: cache still valid, #{@@change_id}/#{change_id}"
      return true
    end
    logger.debug "Setting.cache_valid?: cache has changed, #{@@change_id}/#{change_id}"
    false
  end

  # convert state into hash to be able to store it as store
  def state_check
    return if !state
    return if state && state.respond_to?('has_key?') && state.key?(:value)
    self.state_current = { value: state }
  end
end
