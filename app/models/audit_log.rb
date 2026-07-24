# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AuditLog < ApplicationModel
  include ChecksClientNotification
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch

  include AuditLog::LogsAssociationUpdates
  include AuditLog::LogsRoleAssignments

  belongs_to :user, optional: true

  belongs_to :auditable, polymorphic: true, optional: true

  search_index_attributes_ignored :auditable

  validates :action_type, presence: true

  scope :sorted, -> { order(created_at: :desc) }

  before_create :set_user_fullname, :set_switched_from_user, :set_source_ip

=begin

suspend all audit logging for the duration of a block (thread-local)

  AuditLog.suspend do
    user.update!(firstname: 'not audited')
  end

also available as Transaction.execute(disable_audit_log: true) { ... }

=end

  def self.suspend
    original = suspended?
    self.suspended = true
    yield
  ensure
    self.suspended = original
  end

  def self.suspended?
    !!Thread.current[:audit_log_suspended]
  end

  def self.suspended=(value)
    Thread.current[:audit_log_suspended] = value
  end

  def self.cleanup(diff = 12.months)
    where(created_at: ...diff.ago)
      .destroy_all

    true
  end

  private

  def set_user_fullname
    return if user_fullname.present?
    return if user.blank?

    self.user_fullname = if UserInfo.current_switched_from_user
                           "#{UserInfo.current_switched_from_user.fullname} → #{user.fullname}"
                         else
                           user.fullname
                         end
  end

  def set_switched_from_user
    return if UserInfo.current_switched_from_user.blank?

    preferences['switched_from_user_id']       = UserInfo.current_switched_from_user.id
    preferences['switched_from_user_fullname'] = UserInfo.current_switched_from_user.fullname
  end

  def set_source_ip
    return if source_ip.present?

    self.source_ip = UserInfo.current_ip
    return if source_ip.present?

    self.source_ip = __('Rails console') if Rails.const_defined?(:Console)
    return if source_ip.present?

    self.source_ip = __('Rails runner') if defined?(Rails::Command::RunnerCommand)
  end
end
