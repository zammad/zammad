# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Validations::DataPrivacyTaskValidator < ActiveModel::Validator

  attr_reader :record

  delegate :deletable, to: :record

  def validate(record)
    @record = record

    check_for_deletable_type
    check_for_existing_task
    check_for_user
  end

  private

  def check_for_deletable_type
    return if !record.deletable_type_changed?
    return if [User, Ticket].any? { deletable.is_a?(_1) }

    record.errors.add(:base, __('Data privacy task allows to delete a user or a ticket only.'))
  end

  def check_for_user
    return if !record.deletable_id_changed?
    return if !deletable.is_a?(User)

    check_for_system_user
    check_for_current_user
    check_for_last_admin
  end

  def check_for_system_user
    return if deletable.id != 1

    record.errors.add(:base, __('It is not possible to delete the system user.'))
  end

  def check_for_current_user
    return if deletable.id != UserInfo.current_user_id

    record.errors.add(:base, __('It is not possible to delete your current account.'))
  end

  def check_for_last_admin
    return if !last_admin?

    record.errors.add(:base, __('It is not possible to delete the last account with admin permissions.'))
  end

  def check_for_existing_task
    return if !record.deletable_id_changed?
    return if !tasks_exists?

    record.errors.add(:base, __('Selected object is already queued for deletion.'))
  end

  def tasks_exists?
    DataPrivacyTask
      .where.not(id:    record.id)
      .where.not(state: 'failed')
      .exists? deletable: deletable
  end

  def last_admin?
    return false if !deletable_is_admin?

    future_admin_ids.blank?
  end

  def future_admin_ids
    other_admin_ids - existing_jobs_admin_ids
  end

  def other_admin_ids
    admin_users.where.not(id: deletable.id).pluck(:id)
  end

  def deletable_is_admin?
    admin_users.exists?(id: deletable.id)
  end

  def existing_jobs_admin_ids
    DataPrivacyTask.where(
      deletable_id:   other_admin_ids,
      deletable_type: 'User'
    ).pluck(:deletable_id)
  end

  def admin_users
    User.with_permissions('admin')
  end
end
