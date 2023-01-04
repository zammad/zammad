# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class StorePolicy < ApplicationPolicy

  # Store objects are authorized based on the policy of the object that "owns" them,
  #   like the ticket or knowledge base answer they are attached to.
  # If no owner class or record can be found, forbid access by default.

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

  def store_object_class
    record.store_object&.name&.safe_constantize
  end

  def store_object_policy(target)
    Pundit.policy user, target
  end

  def store_object_owner
    if store_object_class == UploadCache
      return UploadCache.new(record.o_id)
    end

    store_object_class&.find record.o_id
  end
end
