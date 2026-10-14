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
  def related_accessible?(related_object = record.related_object)
    return false if related_object.blank?
    return own_standalone?(related_object) if related_object.is_a?(OnlineNotificationStandalone)

    policy = Pundit.policy(user, related_object)
    return false if !policy.respond_to?(:show?)

    # The assets ship the related object in full, so a field-scoped result is not enough.
    policy.show? == true
  end

  private

  def owner?
    user == record.user
  end

  def own_standalone?(standalone)
    OnlineNotification.own_standalone_ids(user).exists?(standalone.id)
  end

  def without_relation_permission_field_scope
    @without_relation_permission_field_scope ||=
      ApplicationPolicy::FieldScope.new(allow: %i[seen type_name object_name created_at updated_at])
  end
end
