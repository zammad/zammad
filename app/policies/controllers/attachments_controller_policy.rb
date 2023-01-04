# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::AttachmentsControllerPolicy < Controllers::ApplicationControllerPolicy
  def show?
    store_object_policy(store_object_owner)&.show?
  end

  def destroy?
    store_object_policy(store_object_owner)&.destroy?
  end

  def user_required?
    false
  end

  def custom_exception
    ActiveRecord::RecordNotFound.new
  end

  private

  def download_file
    record.send(:download_file)
  end

  def store_object_class
    download_file
      &.store_object
      &.name
      &.safe_constantize
  end

  def store_object_policy(target)
    Pundit.policy user, target
  end

  def store_object_owner
    store_object_class
      &.find download_file.o_id
  end
end
