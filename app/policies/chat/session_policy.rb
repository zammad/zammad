# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Chat::SessionPolicy < ApplicationPolicy
  # Every chat agent may read every conversation, as in the old UI, where a session found through
  #   search opens for any of them. Writing, ending and transferring stay with the agent who runs it,
  #   which the services enforce.
  def read_conversation?
    user.permissions?('chat.agent')
  end

  # A session sent back to a queue keeps its agent until another one takes it, and pushes nothing.
  def subscribe?
    read_conversation? && record.state != 'waiting'
  end

  # What the generic tag mutations ask of a taggable record: the window of a session is its
  #   agent's, also after it closed. Being shared with tickets, those mutations cannot require the
  #   chat setting themselves.
  def agent_update_access?
    Setting.get('chat') && user.permissions?('chat.agent') && record.user_id == user.id
  end
end
