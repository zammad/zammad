# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::MentionsControllerPolicy < Controllers::ApplicationControllerPolicy
  def index?
    object_accessible?
  end

  def create?
    object_accessible?
  end

  def destroy?
    mentioned_user?
  end

  private

  def object_accessible?
    Mention.mentionable? record.mentionable_object, user
  rescue Exceptions::UnprocessableEntity => e
    not_authorized(e)
  end

  def mentioned_user?
    mention = Mention.find_by id: record.params[:id]

    mention&.user_id == user.id
  end
end
