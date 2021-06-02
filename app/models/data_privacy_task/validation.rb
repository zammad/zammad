# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class DataPrivacyTask::Validation < ActiveModel::Validator

  attr_reader :record

  def validate(record)
    @record = record

    check_for_user
    check_for_system_user
    check_for_current_user
    check_for_last_admin
    check_for_existing_task
  end

  private

  def check_for_user
    return if !record.deletable_type_changed?
    return if deletable_is_user?

    invalid_because(:deletable, 'is not a User')
  end

  def check_for_system_user
    return if !record.deletable_id_changed?
    return if !deletable_is_user?
    return if deletable.id != 1

    invalid_because(:deletable, 'is undeletable system User with ID 1')
  end

  def check_for_current_user
    return if !record.deletable_id_changed?
    return if !deletable_is_user?
    return if deletable.id != UserInfo.current_user_id

    invalid_because(:deletable, 'is your current account')
  end

  def check_for_last_admin
    return if !record.deletable_id_changed?
    return if !deletable_is_user?
    return if !last_admin?

    invalid_because(:deletable, 'is last account with admin permissions')
  end

  def check_for_existing_task
    return if !record.deletable_id_changed?
    return if !deletable_is_user?
    return if !tasks_exists?

    invalid_because(:deletable, 'has an existing DataPrivacyTask queued')
  end

  def deletable_is_user?
    deletable.is_a?(User)
  end

  def deletable
    record.deletable
  end

  def invalid_because(attribute, message)
    record.errors.add attribute, message
  end

  def tasks_exists?
    DataPrivacyTask.where(
      deletable: deletable
    ).where.not(
      id:    record.id,
      state: 'failed'
    ).exists?
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
