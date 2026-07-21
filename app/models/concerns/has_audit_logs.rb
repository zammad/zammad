# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module HasAuditLogs
  extend ActiveSupport::Concern

  AUDIT_LOG_IGNORED_ATTRIBUTES = %w[id created_at updated_at created_by_id updated_by_id note].freeze

  included do
    has_many :audit_logs, as: :auditable, dependent: nil

    association_attributes_ignored :audit_logs

    class_attribute :audit_log_name_attribute, instance_writer: false, default: 'name'

    class_attribute :audit_log_attributes_tracked, instance_writer: false, default: [].freeze

    class_attribute :audit_log_attributes_ignored, instance_writer: false, default: [].freeze

    class_attribute :audit_log_if, instance_writer: false

    # prepended so that it wraps all other save callbacks regardless of the include position
    around_save :audit_log_track_creating, prepend: true

    after_create  :audit_log_create
    after_update  :audit_log_update
    after_destroy :audit_log_destroy
  end

  def audit_log_creating?
    !!@audit_log_creating
  end

=begin

log object creation in the audit log - will be executed automatically

  model = Model.find(123)
  model.audit_log_create

=end

  def audit_log_create
    return if audit_log_tracked_attributes.present?

    audit_log_add('create', {}, audit_log_snapshot(attributes))
  end

=begin

log object update in the audit log - will be executed automatically

  model = Model.find(123)
  model.audit_log_update

=end

  def audit_log_update
    changes = saved_changes.except(*audit_log_ignored_attributes)
    changes = changes.slice(*audit_log_tracked_attributes) if audit_log_tracked_attributes.present?
    return if changes.blank?

    if audit_log_tracked_attributes.present?
      value_from = audit_log_snapshot(changes.transform_values(&:first))
      value_to   = audit_log_snapshot(changes.transform_values(&:last))
    else
      value_from = audit_log_snapshot(attributes.merge(changes.transform_values(&:first)))
      value_to   = audit_log_snapshot(attributes)
    end

    audit_log_add('update', value_from, value_to, changed_attributes: audit_log_changed_attributes(changes))
  end

=begin

log object destruction in the audit log - will be executed automatically

  model = Model.find(123)
  model.audit_log_destroy

=end

  def audit_log_destroy
    return if audit_log_tracked_attributes.present?

    audit_log_add('destroy', audit_log_snapshot(attributes), {})
  end

  private

  # the around_save callback wraps the whole save including the persisting of
  # associated records, e.g. the roles of a newly created user -
  # nested saves triggered by callbacks must not reset the state of the outer save
  def audit_log_track_creating
    outer_state = @audit_log_creating
    @audit_log_creating = outer_state || new_record?
    yield
  ensure
    @audit_log_creating = outer_state
  end

  # sensitive values are masked via CanSensitiveAssets (SENSITIVE_FIELDS) if the model includes it
  def audit_log_snapshot(raw_attributes)
    snapshot = raw_attributes.except(*audit_log_ignored_attributes)
    snapshot = mask_sensitive_values(snapshot, self) if respond_to?(:mask_sensitive_values)

    audit_log_mask(snapshot)
  end

  def audit_log_ignored_attributes
    @audit_log_ignored_attributes ||= AUDIT_LOG_IGNORED_ATTRIBUTES + audit_log_attributes_ignored.map(&:to_s)
  end

  # callback to overwrite for model-specific masking of audit log snapshots, may also rename attributes
  def audit_log_mask(snapshot)
    snapshot
  end

  # masks may rename attributes, so the changed attributes are derived from a masked snapshot
  def audit_log_changed_attributes(changes)
    audit_log_snapshot(changes.transform_values(&:last)).keys
  end

  def audit_log_name
    return if !respond_to?(audit_log_name_attribute)

    send(audit_log_name_attribute)
  end

  def audit_log_tracked_attributes
    @audit_log_tracked_attributes ||= audit_log_attributes_tracked.map(&:to_s)
  end

  def audit_log_condition_met?
    return true if audit_log_if.blank?

    !!send(audit_log_if)
  end

  def audit_log_add(action_type, value_from, value_to, preferences = {})
    return if AuditLog.suspended?
    return if !Setting.get('system_init_done')
    return if !audit_log_condition_met?

    return if !ActiveRecord::Base.connection.data_source_exists?('audit_logs')

    AuditLog.create!(
      action_type:    action_type,
      auditable:      self,
      auditable_name: audit_log_name,
      user_id:        UserInfo.current_user_id,
      value_from:     value_from,
      value_to:       value_to,
      preferences:    preferences,
    )
  end
end
