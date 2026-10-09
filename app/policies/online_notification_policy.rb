# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OnlineNotificationPolicy < ApplicationPolicy
  def show?
    return false if !owner?
    return true  if related_accessible?

    without_relation_permission_field_scope
  end

  def destroy?
    owner?
  end

  def update?
    owner?
  end

  # Whether the user may see the object the notification is about, not only
  #   that the notification exists.
  def related_accessible?
    return false if !record.related_object

    case record.related_object
    when OnlineNotificationStandalone
      true
    else
      Pundit
        .policy(user, record.related_object)
        .show?
    end
  end

  private

  def owner?
    user == record.user
  end

  def without_relation_permission_field_scope
    @without_relation_permission_field_scope ||=
      ApplicationPolicy::FieldScope.new(allow: %i[seen type_name object_name created_at updated_at])
  end
end
