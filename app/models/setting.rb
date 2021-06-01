# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Setting < ApplicationModel
  store         :options
  store         :state_current
  store         :state_initial
  store         :preferences
  before_create :state_check, :set_initial, :check_broadcast
  after_create  :reset_change_id, :reset_cache
  before_update :state_check, :check_broadcast
  after_update  :reset_change_id, :reset_cache

  attr_accessor :state

  @@current         = {} # rubocop:disable Style/ClassVars
  @@raw             = {} # rubocop:disable Style/ClassVars
  @@change_id       = nil # rubocop:disable Style/ClassVars
  @@last_changed_at = nil # rubocop:disable Style/ClassVars
  @@lookup_at       = nil # rubocop:disable Style/ClassVars
  @@lookup_timeout  = if ENV['ZAMMAD_SETTING_TTL'] # rubocop:disable Style/ClassVars
                        ENV['ZAMMAD_SETTING_TTL'].to_i.seconds
                      else
                        15.seconds
                      end

=begin

set config setting

  Setting.set('some_config_name', some_value)

=end

  def self.set(name, value)
    setting = Setting.find_by(name: name)
    if !setting
      raise "Can't find config setting '#{name}'"
    end

    setting.state_current = { value: value }
    setting.save!
    logger.info "Setting.set('#{name}', #{value.inspect})"
    true
  end

=begin

get config setting

  value = Setting.get('some_config_name')

=end

  def self.get(name)
    load
    @@current[name].deep_dup # prevents accidental modification of settings in console
  end

=begin

reset config setting to default

  Setting.reset('some_config_name')

  Setting.reset('some_config_name', force) # true|false - force it false per default

=end

  def self.reset(name, force = false)
    setting = Setting.find_by(name: name)
    if !setting
      raise "Can't find config setting '#{name}'"
    end
    return true if !force && setting.state_current == setting.state_initial

    setting.state_current = setting.state_initial
    setting.save!
    logger.info "Setting.reset('#{name}', #{setting.state_current.inspect})"
    true
  end

=begin

reload config settings

  Setting.reload

=end

  def self.reload
    @@last_changed_at = nil # rubocop:disable Style/ClassVars
    load(true)
  end

  private

  # load values and cache them
  def self.load(force = false)

    # check if config is already generated
    return false if !force && @@current.present? && cache_valid?

    # read all or only changed since last read
    latest = Setting.order(updated_at: :desc).limit(1).pluck(:updated_at)
    settings = if @@last_changed_at && @@current.present?
                 Setting.where('updated_at > ?', @@last_changed_at).order(:id).pluck(:name, :state_current)
               else
                 Setting.order(:id).pluck(:name, :state_current)
               end
    if latest
      @@last_changed_at = latest[0] # rubocop:disable Style/ClassVars
    end

    if settings.present?
      settings.each do |setting|
        @@raw[setting[0]] = setting[1]['value']
      end
      @@raw.each do |key, value|
        if value.class != String
          @@current[key] = value
          next
        end
        @@current[key] = value.gsub(%r{\#\{config\.(.+?)\}}) do
          @@raw[$1].to_s
        end
      end
    end

    @@change_id = Cache.read('Setting::ChangeId') # rubocop:disable Style/ClassVars
    @@lookup_at = Time.now.to_i # rubocop:disable Style/ClassVars
    true
  end
  private_class_method :load

  # set initial value in state_initial
  def set_initial
    self.state_initial = state_current
    true
  end

  def reset_change_id
    @@current[name] = state_current[:value]
    change_id = rand(999_999_999).to_s
    logger.debug { "Setting.reset_change_id: set new cache, #{change_id}" }
    Cache.write('Setting::ChangeId', change_id, { expires_in: 24.hours })
    @@lookup_at = nil # rubocop:disable Style/ClassVars
    true
  end

  def reset_cache
    return true if preferences[:cache].blank?

    preferences[:cache].each do |key|
      Cache.delete(key)
    end
    true
  end

  # check if cache is still valid
  def self.cache_valid?
    if @@lookup_at && @@lookup_at > Time.now.to_i - @@lookup_timeout
      #logger.debug "Setting.cache_valid?: cache_id has been set within last #{@@lookup_timeout} seconds"
      return true
    end

    change_id = Cache.read('Setting::ChangeId')
    if @@change_id && change_id == @@change_id
      @@lookup_at = Time.now.to_i # rubocop:disable Style/ClassVars
      #logger.debug "Setting.cache_valid?: cache still valid, #{@@change_id}/#{change_id}"
      return true
    end
    #logger.debug "Setting.cache_valid?: cache has changed, #{@@change_id}/#{change_id}"
    false
  end
  private_class_method :cache_valid?

  # convert state into hash to be able to store it as store
  def state_check
    return true if state.nil? # allow false value
    return true if state.try(:key?, :value)

    self.state_current = { value: state }
    true
  end

  # notify clients about public config changes
  def check_broadcast
    return true if frontend != true

    value = state_current
    if state_current.key?(:value)
      value = state_current[:value]
    end
    Sessions.broadcast(
      {
        event: 'config_update',
        data:  { name: name, value: value }
      },
      'public'
    )
    true
  end
end
