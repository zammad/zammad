# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SettingBackendClassValidation < ActiveRecord::Migration[8.0]
  # The settings of these areas register one particular backend each.
  AREAS = %w[
    Security::Authentication
    Dashboard::Stats
    Postmaster::PreFilter
    Postmaster::PostFilter
    Transaction::Backend::Sync
    Transaction::Backend::Async
  ].freeze

  NAMES = %w[
    image_backend
    geo_ip_backend
    geo_location_backend
    geo_calendar_backend
    ticket_number
    import_backends
  ].freeze

  # Migration 20170529000002 set the renamed filter class on the existing record, so systems from
  #   before it still have the removed class as the initial value of this setting.
  RENAMED_INITIAL_VALUES = {
    '0900_postmaster_filter_bounce_follow_up_check' => ['Channel::Filter::BounceCheck', 'Channel::Filter::BounceFollowUpCheck'],
  }.freeze

  def up
    return if !Setting.exists?(name: 'system_init_done')

    Setting.where(area: AREAS).or(Setting.where(name: NAMES)).find_each do |setting|
      realign_initial_value(setting)

      validations = Array(setting.preferences[:validations]) | ['Setting::Validation::BackendClass']
      setting.preferences = setting.preferences.merge(validations: validations)

      correct_rejected_value(setting)
      warn_unloadable_value(setting)

      setting.skip_validate = true
      setting.save!
    end
  end

  private

  def realign_initial_value(setting)
    removed, renamed = RENAMED_INITIAL_VALUES[setting.name]
    return if removed.nil? || setting.state_initial[:value] != removed

    setting.state_initial = setting.state_initial.merge(value: renamed)
  end

  # A rejected value stored before must not stop the upgrade: a registered backend is reset to the
  #   one backend its setting accepts (a pre filter outside Channel::Filter would stop processing
  #   every mail), the other settings keep their value and log it.
  def correct_rejected_value(setting)
    result = Setting::Validation::BackendClass.new(setting).check_value
    return if result[:success]

    if AREAS.include?(setting.area)
      Rails.logger.warn "Setting '#{setting.name}' is reset to its initial value, as its new validation rejects the stored one: #{result[:message]}"
      setting.state_current = setting.state_initial
      return
    end

    Rails.logger.warn "Setting '#{setting.name}' keeps a value its new validation rejects: #{result[:message]} Correct it, as the code using it may skip it or fail on it."
  end

  # A registered backend passes its validation with the class it was created with, but the code
  #   using it loads that class only from its own namespace (e.g. not one of a removed add-on).
  def warn_unloadable_value(setting)
    return if AREAS.exclude?(setting.area)

    name = registered_name(setting)
    return if name.blank? || loadable?(setting.area, name)

    Rails.logger.warn "Setting '#{setting.name}' registers '#{name}', which the code using it can't load: a postmaster pre filter then fails every mail, another backend is skipped. Correct it."
  end

  def registered_name(setting)
    value = setting.state_current[:value]

    setting.area == 'Security::Authentication' ? value.try(:dig, :adapter) : value
  end

  def loadable?(area, name)
    case area
    when 'Security::Authentication'
      Auth::Backend.adapter_class(name).present?
    when 'Dashboard::Stats'
      ApplicationLib.load_adapter(name, namespace: Stats).present?
    when 'Postmaster::PreFilter', 'Postmaster::PostFilter'
      ApplicationLib.load_adapter(name, namespace: Channel::Filter).present?
    when 'Transaction::Backend::Sync', 'Transaction::Backend::Async'
      ApplicationLib.load_adapter(name, namespace: Transaction).present?
    end
  end
end
