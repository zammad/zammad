# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ChecksKbClientNotificationJob < ApplicationJob
  include HasActiveJobLock

  def lock_key
    # "ChecksKbClientNotificationJob/KnowledgeBase::Answer/42/destroy"
    "#{self.class.name}/#{arguments[0]}/#{arguments[1]}/#{arguments[2]}"
  end

  def perform(klass_name, id, event)
    object = klass_name.constantize.find_by(id: id)
    return if object.blank?

    level = needs_editor?(object) ? 'editor' : '*'

    payload = {
      event: 'kb_data_changed',
      data:  build_data(object, event)
    }

    users_for(level).each { |user| notify(user, payload) }
  end

  def build_data(object, event)
    timestamp = event == :destroy ? Time.zone.now : object.updated_at
    url       = event == :destroy ? nil           : object.api_url

    {
      class:     object.class.to_s,
      event:     event,
      id:        object.id,
      timestamp: timestamp,
      url:       url
    }
  end

  def needs_editor?(object)
    case object
    when KnowledgeBase::Answer
      object.can_be_published_aasm.draft?
    when KnowledgeBase::Category
      !object.internal_content?
    else
      false
    end
  end

  def notify(user, payload)
    PushMessages.send_to(user.id, payload)
  end

  def users_for(permission_suffix)
    Sessions
      .sessions
      .map { |client_id| Sessions.get(client_id)&.dig(:user, 'id') }
      .compact
      .map { |user_id| User.find_by(id: user_id) }
      .compact
      .select { |user| user.permissions? "knowledge_base.#{permission_suffix}" }
  end

  def self.notify_later(object, event)
    perform_later(object.class.to_s, object.id, event.to_s)
  end
end
