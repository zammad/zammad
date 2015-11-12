# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Chat < ApplicationModel
  has_many            :chat_topics
  validates           :name, presence: true

  def customer_state(session_id = nil)
    return { state: 'chat_disabled' } if !Setting.get('chat')

    # reconnect
    if session_id
      chat_session = Chat::Session.find_by(session_id: session_id, state: %w(waiting running))
      user = nil
      if chat_session && chat_session.user_id
        chat_user = User.find(chat_session.user_id)
        url = nil
        if chat_user.image && chat_user.image != 'none'
          url = "/api/v1/users/image/#{chat_user.image}"
        end
        user = {
          name: chat_user.fullname,
          avatar: url,
        }
      end

      if chat_session
        session = Chat.session_state(session_id)
        if session && !session.empty?
          return {
            state: 'reconnect',
            session: session,
            agent: user,
          }
        end
      end
    end

    if Chat::Agent.where(active: true).where('updated_at > ?', Time.zone.now - 2.minutes).count > 0
      if active_chat_count >= max_queue
        return {
          state: 'no_seats_available',
          queue: seads_available,
        }
      else
        return { state: 'online' }
      end
    end

    { state: 'offline' }
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

class Chat::Topic < ApplicationModel
end

class Chat::Agent < ApplicationModel

  def seads_available
    concurrent - active_chat_count
  end

  def active_chat_count
    Chat::Session.where(state: %w(waiting running), user_id: updated_by_id).count
  end

  def self.state(user_id, state = nil)
    chat_agent = Chat::Agent.find_by(
      updated_by_id: user_id
    )
    if state.nil?
      return false if !chat_agent
      return chat_agent.active
    end
    if chat_agent
      chat_agent.active = state
      chat_agent.updated_at = Time.zone.now
      chat_agent.save
    else
      Chat::Agent.create(
        active: state,
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
      chat_agent.update_attributes(params)
    else
      Chat::Agent.create(params)
    end
  end
end

class Chat::Session < ApplicationModel
  before_create :generate_session_id
  store         :preferences

  def generate_session_id
    self.session_id = Digest::MD5.hexdigest(Time.zone.now.to_s + rand(99_999_999_999_999).to_s)
  end

  def add_recipient(client_id, store = false)
    if !preferences[:participants]
      preferences[:participants] = []
    end
    return preferences[:participants] if preferences[:participants].include?(client_id)
    preferences[:participants].push client_id
    if store
      save
    end
    preferences[:participants]
  end

  def send_to_recipients(message, ignore_client_id = nil)
    preferences[:participants].each {|local_client_id|
      next if local_client_id == ignore_client_id
      Sessions.send(local_client_id, message)
    }
    true
  end
end

class Chat::Message < ApplicationModel
end
