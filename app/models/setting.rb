# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Class variables are used here as performance optimization.
# Technically it is not thread-safe, but it never caused issues.
# rubocop:disable-next Style/ClassVars
class Setting < ApplicationModel
  include ChecksClientNotification

  include Setting::HasAuditLogs

  SENSITIVE_SETTING_NAMES = %w[secret auth_ password pw credential endpoint_key _config _token recovery_codes pwd captcha_options private_key].freeze

  # Not sent to the frontend, but harmless, and what a template needs to rebuild the ticket
  # reference and the notification sender.
  TEMPLATE_READABLE_SETTINGS = %w[ticket_hook_divider notification_sender].freeze

  # How far a setting's value travels, widest audience first: to anonymous clients, to logged-in
  # users, to templates, or no further than the backend.
  REACH = { public: 0, authenticated: 1, templates: 2, backend: 3 }.freeze

  store         :options
  store         :state_current
  store         :state_initial
  store         :preferences
  before_validation :transform
  before_validation :state_check
  before_create :set_initial
  after_save    :reset_class_cache_key
  after_commit  :reset_other_caches, :broadcast_frontend, :check_refresh, :schedule_vector_index_reconcile

  validates_with Setting::Validator, if: -> { !skip_validate }

  attr_accessor :state, :skip_validate
  attr_reader :vector_index_rebuild_started

  @@current         = {}
  @@raw             = {}
  @@reach           = {}
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

  def self.set(name, value, validate: true)
    setting = Setting.find_by(name: name)
    if !setting
      raise "Can't find config setting '#{name}'"
    end

    setting.skip_validate = !validate

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

  # True for a setting a template may read: one sent to the frontend, or one of the few named ones.
  def self.template_readable?(name)
    load
    travels_to?(name, REACH[:templates])
  end

  def self.known?(name)
    load
    @@reach.key?(name)
  end

  # True when the value of `referrer` takes in `#{config.<name>}`.
  def self.reference_kept?(referrer, name)
    load
    takes_in?(referrer, name)
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

  def sensitive?
    SENSITIVE_SETTING_NAMES.any? { |word| name.include?(word) }
  end

  def protected?
    preferences[:protected].present?
  end

  # Shared by SettingPolicy and its denial message, so the two cannot name different permissions.
  # Only a missing permission falls back to admin: an empty list still grants nobody.
  def required_permission
    preferences[:permission] || ['admin']
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

    settings      = settings_query.pluck(:name, :state_current, :frontend)
    authenticated = authenticated_names(settings_query)

    @@last_changed_at = [Time.current, latest].min if latest

    if settings.present?
      settings.each do |name, state_current, frontend|
        @@raw[name]   = state_current['value']
        @@reach[name] = reach(name, frontend, authenticated.include?(name))
      end

      @@raw.each do |key, value|
        if key == 'notification_sender'
          @@current[key] = sanitize_notification_sender value
          next
        end

        @@current[key] = interpolate_value key, value
      end
    end

    @@query_cache_key = base_query.cache_key_with_version
    @@lookup_at = Time.current

    true
  end
  private_class_method :load

  # Deserializing preferences is costly, and only frontend settings need them.
  def self.authenticated_names(settings_query)
    settings_query.where(frontend: true).pluck(:name, :preferences)
      .filter_map { |name, preferences| name if preferences['authentication'] }
      .to_set
  end
  private_class_method :authenticated_names

  def self.reach(name, frontend, authenticated)
    return REACH[:templates] if TEMPLATE_READABLE_SETTINGS.include?(name)
    return REACH[:backend] if !frontend

    authenticated ? REACH[:authenticated] : REACH[:public]
  end
  private_class_method :reach

  def self.travels_to?(name, reach)
    @@reach.key?(name) && @@reach[name] <= reach
  end
  private_class_method :travels_to?

  # A value takes in only what its own readers may see anyway: a template may read `name`, and it
  # travels at least as far as `referrer` does, so a public setting takes in public settings only.
  def self.takes_in?(referrer, name)
    return false if !@@reach.key?(referrer)

    travels_to?(name, [@@reach[referrer], REACH[:templates]].min)
  end
  private_class_method :takes_in?

  def self.interpolate_value(referrer, input)
    replace_config_references(referrer, input) { |_name, value| value }
  end
  private_class_method :interpolate_value

  def self.sanitize_notification_sender(input)
    replace_config_references('notification_sender', input) do |name, value|
      case name
      when 'fqdn'
        value.sub(%r{:\d+$}, '') # strip port from fqdn
      when 'product_name'
        "\"#{value.gsub(%r{"}, "''")}\"" # quote and replace double quotes
      else
        value
      end
    end
  end
  private_class_method :sanitize_notification_sender

  # A reference the value does not take in is dropped, as an unknown one always was.
  def self.replace_config_references(referrer, input)
    return input if !input.is_a? String

    input.gsub(%r{\#\{config\.(.+?)\}}) do
      name = $1
      next '' if !takes_in?(referrer, name)

      yield name, @@raw[name].to_s
    end
  end
  private_class_method :replace_config_references

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

  # Notify clients about config changes (frontend only!).
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

    # The value is handed over rather than looked up by the subscribers, since the process serving
    #   a subscriber may still cache the previous value of this setting (see .cache_valid?).
    Gql::Subscriptions::ConfigUpdates.trigger({ 'name' => name, 'value' => value, 'authentication' => preferences[:authentication] })
  end

  def notify_clients_send(data)
    permissions = preferences['permission']

    if permissions.present?
      User.with_permissions(permissions).each do |user|
        PushMessages.send_to(user.id, data[:message])
      end

      return
    end

    User.with_permissions('admin.*').each do |user|
      PushMessages.send_to(user.id, data[:message])
    end
  end

  # NB: Force users to reload on SAML credentials config changes
  #   This is needed because the setting is not frontend related,
  #   so we can't rely on 'config_update_local' mechanism to kick in
  # https://github.com/zammad/zammad/issues/4263
  def check_refresh
    return if ['auth_saml_credentials'].exclude?(name)

    AppVersion.trigger_browser_reload AppVersion::MSG_CONFIG_CHANGED
  end

  # Names that decide whether anything embeds at all - a change to either can leave the vector index
  # out of step with what is configured.
  VECTOR_INDEX_RECONCILE_SETTINGS = %w[ai_provider vectordb_enabled].freeze

  # A configuration change made while one of these was disabled must not be lost: re-enabling
  # compares what the index holds against what is configured now, rather than trusting that nothing
  # changed just because nothing could have rebuilt it in the meantime. A short toggle where nothing
  # actually changed reconciles to a no-op.
  #
  # `vectordb_enabled` is here for the writers that pass no controller: the admin UI posts to
  # /ai/vector_index/sync after flipping it, but `Setting.set` from the console or the API does not,
  # and the first build has to happen either way.
  #
  # Guarded on the vectordb settings existing at all: this runs on every setting save, including the
  # seed run that creates `ai_provider` itself before `vectordb_enabled` exists yet.
  def schedule_vector_index_reconcile
    return if VECTOR_INDEX_RECONCILE_SETTINGS.exclude?(name)
    return if !Setting.exists?(name: 'vectordb_enabled')

    @vector_index_rebuild_started = Service::AI::VectorDB::Reconcile.execute == true
  end

  def transform
    Array(preferences[:transformations])
      .map { |klass| klass.constantize.new(self).run }
  end
end
