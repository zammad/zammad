# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Class variables are used here as performance optimization.
# Technically it is not thread-safe, but it never caused issues.
# rubocop:disable Style/ClassVars
class Setting < ApplicationModel
  store         :options
  store         :state_current
  store         :state_initial
  store         :preferences
  before_validation :state_check
  before_create :set_initial
  after_save    :reset_class_cache_key
  after_commit  :reset_other_caches, :broadcast_frontend, :check_refresh

  validates_with Setting::Validator

  attr_accessor :state

  @@current         = {}
  @@raw             = {}
  @@query_cache_key = nil
  @@last_changed_at = nil
  @@lookup_at       = nil
  @@lookup_timeout  = if ENV['ZAMMAD_SETTING_TTL']
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

    logger.info "Setting.set('#{name}', #{filter_param(name, value).inspect})"
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

    logger.info "Setting.reset('#{name}', #{filter_param(name, setting.state_current).inspect})"
    true
  end

=begin

reload config settings

  Setting.reload

=end

  def self.reload
    @@last_changed_at = nil
    load(true)
  end

  # check if cache is still valid
  def self.cache_valid?
    # Check if last last lookup was recent enough
    if @@lookup_at && @@lookup_at > @@lookup_timeout.ago
      # logger.debug "Setting.cache_valid?: cache_id has been set within last #{@@lookup_timeout} seconds"
      return true
    end

    if @@query_cache_key && Setting.reorder(:id).cache_key_with_version == @@query_cache_key
      @@lookup_at = Time.current

      return true
    end

    false
  end

  # Used to mask values of sensitive settings such as passwords, tokens etc.
  def self.filter_param(key, value)
    @@parameter_filter ||= ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    @@parameter_filter.filter_param(key, value)
  end

  private

  # load values and cache them
  def self.load(force = false)

    # check if config is already generated
    return false if !force && @@current.present? && cache_valid?

    # read all or only changed since last read
    latest = Setting.maximum(:updated_at)

    base_query = Setting.reorder(:id)

    settings_query = if @@last_changed_at && @@current.present?
                       base_query.where(updated_at: @@last_changed_at..)
                     else
                       base_query
                     end

    settings = settings_query.pluck(:name, :state_current)

    @@last_changed_at = [Time.current, latest].min if latest

    if settings.present?
      settings.each do |setting|
        @@raw[setting[0]] = setting[1]['value']
      end

      @@raw.each do |key, value|
        if key == 'notification_sender'
          @@current[key] = sanitize_notification_sender value
          next
        end

        @@current[key] = interpolate_value value
      end
    end

    @@query_cache_key = base_query.cache_key_with_version
    @@lookup_at = Time.current

    true
  end
  private_class_method :load

  def self.interpolate_value(input)
    return input if !input.is_a? String

    input.gsub(%r{\#\{config\.(.+?)\}}) do
      @@raw[$1].to_s
    end
  end
  private_class_method :interpolate_value

  def self.sanitize_notification_sender(input)
    return input if !input.is_a? String

    input.gsub(%r{\#\{config\.(.+?)\}}) do
      placeholder = @@raw[$1].to_s

      case $1
      when 'fqdn'
        placeholder = placeholder.sub(%r{:\d+$}, '') # strip port from fqdn
      when 'product_name'
        placeholder = "\"#{placeholder.gsub(%r{"}, "''")}\"" # quote and replace double quotes
      end

      placeholder
    end
  end
  private_class_method :sanitize_notification_sender

  # set initial value in state_initial
  def set_initial
    self.state_initial = state_current
  end

  def reset_class_cache_key
    @@lookup_at = nil
    @@query_cache_key = nil
  end

  # Resets caches related to the setting in question.
  def reset_other_caches
    return if preferences[:cache].blank?

    Array(preferences[:cache]).each do |key|
      Rails.cache.delete(key)
    end
  end

  # Convert state into hash to be able to store it as store.
  def state_check
    return if state.nil? # allow false value
    return if state.try(:key?, :value)

    self.state_current = { value: state }
  end

  # Notify clients about config changes.
  def broadcast_frontend
    return if !frontend

    # Some setting values use interpolation to reference other settings.
    # This is applied in `Setting.get`, thus direct reading of the value should be avoided.
    value = self.class.get(name)

    Sessions.broadcast(
      {
        event: 'config_update',
        data:  { name: name, value: value }
      },
      preferences[:authentication] ? 'authenticated' : 'public'
    )

    Gql::Subscriptions::ConfigUpdates.trigger(self)
  end

  # NB: Force users to reload on SAML credentials config changes
  #   This is needed because the setting is not frontend related,
  #   so we can't rely on 'config_update_local' mechanism to kick in
  # https://github.com/zammad/zammad/issues/4263
  def check_refresh
    return if ['auth_saml_credentials'].exclude?(name)

    AppVersion.trigger_browser_reload AppVersion::MSG_CONFIG_CHANGED
  end
end
# rubocop:enable Style/ClassVars
