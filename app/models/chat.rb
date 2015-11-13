# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Chat < ApplicationModel
  has_many            :chat_topics
  validates           :name, presence: true

  def customer_state(session_id = nil)
    return { state: 'chat_disabled' } if !Setting.get('chat')

    # reconnect
    if session_id
      chat_session = Chat::Session.find_by(session_id: session_id, state: %w(waiting running))

      if chat_session
        if chat_session.state == 'running'
          user = nil
          if chat_session.user_id
            chat_user = User.find(chat_session.user_id)
            url = nil
            if chat_user.image && chat_user.image != 'none'
              url = "/api/v1/users/image/#{chat_user.image}"
            end
            user = {
              name: chat_user.fullname,
              avatar: url,
            }

            # get queue postion if needed
            session = Chat.session_state(session_id)
            if session
              return {
                state: 'reconnect',
                session: session,
                agent: user,
              }
            end
          end
        elsif chat_session.state == 'waiting'
          return {
            state: 'reconnect',
            position: chat_session.position,
          }
        end
      end
    end

    # check if agents are available
    available_agents = Chat::Agent.where(active: true).where('updated_at > ?', Time.zone.now - 2.minutes).count
    if available_agents == 0
      return { state: 'offline' }
    end

    # if all seads are used
    if active_chat_count >= max_queue
      return {
        state: 'no_seats_available',
        queue: seads_available,
      }
    end

    # seads are available
    { state: 'online' }
  end

  def self.session_state(session_id)
    session_attributes = []
    chat_session = Chat::Session.find_by(session_id: session_id)
    return if !chat_session
    Chat::Message.where(chat_session_id: chat_session.id).each { |message|
      session_attributes.push message.attributes
    }
    session_attributes
  end

  def self.agent_state(user_id)
    return { state: 'chat_disabled' } if !Setting.get('chat')
    actice_sessions = []
    Chat::Session.where(state: 'running', user_id: user_id).order('created_at ASC').each {|session|
      session_attributes = session.attributes
      session_attributes['messages'] = []
      Chat::Message.where(chat_session_id: session.id).each { |message|
        session_attributes['messages'].push message.attributes
      }
      actice_sessions.push session_attributes
    }
    {
      waiting_chat_count: waiting_chat_count,
      running_chat_count: running_chat_count,
      #available_agents: available_agents,
      active_sessions: actice_sessions,
      active: Chat::Agent.state(user_id)
    }
  end

  def self.waiting_chat_count
    Chat::Session.where(state: ['waiting']).count
  end

  def self.running_chat_count
    Chat::Session.where(state: ['running']).count
  end

  def active_chat_count
    Chat::Session.where(state: %w(waiting running)).count
  end

  def available_agents(diff = 2.minutes)
    agents = {}
    Chat::Agent.where(active: true).where('updated_at > ?', Time.zone.now - diff).each {|record|
      agents[record.updated_by_id] = record.concurrent
    }
    agents
  end

  def seads_total(diff = 2.minutes)
    total = 0
    available_agents(diff).each {|_record, concurrent|
      total += concurrent
    }
    total
  end

  def seads_available(diff = 2.minutes)
    seads_total(diff) - active_chat_count
  end
end
