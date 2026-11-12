# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::AppliesChatSession
  extend ActiveSupport::Concern

  def resolve
    if meta[:initial] && chat_agent? && selected_chat_session.present?
      apply_chat_session
    end

    super
  end

  private

  def apply_chat_session
    apply_value = FormUpdater::ApplyValue.new(context:, data:, result:)

    apply_value.perform(field: 'title', config: { 'value' => chat_session_title })
    apply_value.perform(field: 'body', config: { 'value' => chat_session_body })

    tags = selected_chat_session.tag_list
    apply_value.perform(field: 'tags', config: { 'value' => tags }) if tags.present?
  end

  # Users have no time zone of their own, so the start is shown in the system's one.
  def chat_session_title
    timezone = Setting.get('timezone_default')
    started  = Translation.timestamp(current_user.locale, timezone, selected_chat_session.created_at, append_timezone: false)

    Translation.translate(current_user.locale, __('Chat from %s'), started)
  end

  def chat_session_body
    url = ERB::Util.html_escape("#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#customer_chat/session/#{selected_chat_session.id}")

    "<a href=\"#{url}\">#{url}</a>"
  end

  # An unknown id leaves the form as it is. A session of a colleague applies as well: every chat
  #   agent may read every conversation.
  def selected_chat_session
    return @selected_chat_session if defined?(@selected_chat_session)

    gid = meta.dig(:additional_data, 'chatSessionId')

    @selected_chat_session = begin
      Gql::ZammadSchema.authorized_object_from_id(gid, type: Chat::Session, user: current_user, query: :read_conversation?) if gid.present?
    rescue ActiveRecord::RecordNotFound, Exceptions::Forbidden
      nil
    end
  end

  def chat_agent?
    current_user.permissions?('chat.agent')
  end
end
