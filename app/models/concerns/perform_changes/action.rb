# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class PerformChanges::Action
  include Mixin::RequiredSubPaths

  attr_accessor :record, :execution_data, :performable, :origin, :context_data, :user_id
  attr_reader :locale, :timezone

  def self.action_lookup
    @action_lookup ||= descendants.index_by { |action| action.name.demodulize.underscore.to_sym }
  end

  def self.phase
    :before_save
  end

  def initialize(record, execution_data, perform_changes_data)
    @record = record
    @execution_data = execution_data
    @performable = perform_changes_data[:performable]
    @origin = perform_changes_data[:origin]
    @context_data = perform_changes_data[:context_data]
    @user_id = perform_changes_data[:user_id]

    @locale   = fetch_locale
    @timezone = fetch_timezone
  end

  def execute(prepared_actions)
    raise NotImplementedError
  end

  private

  def id
    record.id
  end

  def notification_factory_template_objects
    @notification_factory_template_objects ||= {
      record.class.name.downcase.to_sym => record,
    }
  end

  def fetch_locale
    locale = @performable.try(:localization)

    # Returning nil will use the system default locale in the NotificationFactory classes.
    return nil if locale.blank? || locale == 'system'

    locale
  end

  def fetch_timezone
    timezone = @performable.try(:timezone)

    # Returning nil will use the system default timezone in the NotificationFactory classes.
    return nil if timezone.blank? || timezone == 'system'

    timezone
  end
end
