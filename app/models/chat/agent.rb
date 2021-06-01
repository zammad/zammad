# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Chat::Agent < ApplicationModel

  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

  def seads_available
    concurrent - active_chat_count
  end

  def active_chat_count
    Chat::Session.where(state: %w[waiting running], user_id: updated_by_id).count
  end

  def self.state(user_id, state = nil)
    chat_agent = Chat::Agent.find_by(
      updated_by_id: user_id
    )
    if state.nil?
      return false if !chat_agent

      return chat_agent.active
    end

    # ATTENTION: setter return value indicates whether `active` state has changed
    if chat_agent
      chat_agent.active = state
      # always update `updated_at` to inform other Agent sessions
      # that this Agent session is still active
      chat_agent.updated_at = Time.zone.now
      chat_agent.save

      chat_agent.active_previously_changed?
    else
      Chat::Agent.create(
        active:        state,
        updated_by_id: user_id,
        created_by_id: user_id,
      )
    end
  end

  def self.create_or_update(params)
    chat_agent = Chat::Agent.find_by(
      updated_by_id: params[:updated_by_id]
    )
    if chat_agent
      chat_agent.update!(params)
    else
      Chat::Agent.create(params)
    end
  end
end
