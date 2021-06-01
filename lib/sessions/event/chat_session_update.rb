# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::ChatSessionUpdate < Sessions::Event::ChatBase

  def run
    return super if super
    return if !check_chat_session_exists
    return if !permission_check('chat.agent', 'chat')

    chat_session = current_chat_session

    if @payload['data']['name'] != chat_session.name
      chat_session.name = @payload['data']['name']
      chat_session.save!
    end

    if @payload['data']['tags']
      new_tags = @payload['data']['tags'].split(',')

      new_tags.each(&:strip!)

      tags = chat_session.tag_list
      new_tags.each do |new_tag|
        next if new_tag.blank?
        next if tags.include?(new_tag)

        chat_session.tag_add(new_tag, current_user_id)
      end

      tags.each do |tag|
        next if new_tags.include?(tag)

        chat_session.tag_remove(tag, current_user_id)
      end
    end

    nil
  end

end
