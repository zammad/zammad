# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ChecksKbClientNotificationJob < ApplicationJob
  include HasActiveJobLock

  def lock_key
    # "ChecksKbClientNotificationJob/KnowledgeBase::Answer/42"
    "#{self.class.name}/#{arguments[0]}/#{arguments[1]}"
  end

  def perform(klass_name, object_id)
    object = klass_name.constantize.find_by(id: object_id)
    return if object.blank?

    payload = {
      event: 'kb_data_changed',
      data:  build_data(object)
    }

    active_users.each do |user|
      notify(user, object, payload)
    end
  end

  def build_data(object)
    {
      class:     object.class.name,
      id:        object.id,
      timestamp: object.updated_at,
      url:       object.try(:api_url)
    }
  end

  def notify(user, object, payload)
    return if !user.permissions? 'knowledge_base.*'

    Pundit.authorize user, object, :show?

    PushMessages.send_to(user.id, payload)
  rescue Pundit::NotAuthorizedError
    # do nothing if user is not authorized to access
  end

  def active_users
    Sessions
      .sessions
      .filter_map { |client_id| Sessions.get(client_id)&.dig(:user, 'id') }
      .filter_map { |user_id| User.find_by(id: user_id) }
  end
end
