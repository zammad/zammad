# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Chat < ApplicationModel
  validates :name, presence: true
  store     :preferences

  def customer_state(session_id = nil)
    return { state: 'chat_disabled' } if !Setting.get('chat')

    # reconnect
    if session_id
      chat_session = Chat::Session.find_by(session_id: session_id, state: %w(waiting running))

      if chat_session
        if chat_session.state == 'running'
          user = nil
          if chat_session.user_id
            chat_user = User.lookup(id: chat_session.user_id)
            url = nil
            if chat_user.image && chat_user.image != 'none'
              url = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/api/v1/users/image/#{chat_user.image}"
            end
            user = {
              name: chat_user.fullname,
              avatar: url,
            }

            # get queue postion if needed
            session = Chat::Session.messages_by_session_id(session_id)
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
    if Chat.waiting_chat_count >= max_queue
      return {
        state: 'no_seats_available',
        queue: Chat.waiting_chat_count,
      }
    end

    # seads are available
    { state: 'online' }
  end

  def self.agent_state(user_id)
    return { state: 'chat_disabled' } if !Setting.get('chat')
    assets = {}
    Chat.where(active: true).each {|chat|
      assets = chat.assets(assets)
    }
    {
      waiting_chat_count: waiting_chat_count,
      running_chat_count: running_chat_count,
      active_sessions: Chat::Session.active_chats_by_user_id(user_id),
      active_agents: active_agents,
      seads_available: seads_available,
      seads_total: seads_total,
      active: Chat::Agent.state(user_id),
      assets: assets,
    }
  end

  def self.waiting_chat_count
    Chat::Session.where(state: ['waiting']).count
  end

  def self.running_chat_count
    Chat::Session.where(state: ['running']).count
  end

  def self.active_chat_count
    Chat::Session.where(state: %w(waiting running)).count
  end

  def self.available_agents(diff = 2.minutes)
    agents = {}
    Chat::Agent.where(active: true).where('updated_at > ?', Time.zone.now - diff).each {|record|
      agents[record.updated_by_id] = record.concurrent
    }
    agents
  end

  def self.active_agents(diff = 2.minutes)
    Chat::Agent.where(active: true).where('updated_at > ?', Time.zone.now - diff).count
  end

  def self.seads_total(diff = 2.minutes)
    total = 0
    available_agents(diff).each {|_user_id, concurrent|
      total += concurrent
    }
    total
  end

  def self.seads_available(diff = 2.minutes)
    seads_total(diff) - active_chat_count
  end

=begin

cleanup old chat messages

  Chat.cleanup

optional you can parse the max oldest chat entries

  Chat.cleanup(3.months)

=end

  def self.cleanup(diff = 3.months)
    Chat::Session.where(state: 'closed').where('updated_at < ?', Time.zone.now - diff).each {|chat_session|
      Chat::Message.where(chat_session_id: chat_session.id).delete_all
      chat_session.destroy
    }

    true
  end

=begin

close chat sessions where participients are offline

  Chat.cleanup_close

optional you can parse the max oldest chat sessions

  Chat.cleanup_close(5.minutes)

=end

  def self.cleanup_close(diff = 5.minutes)
    Chat::Session.where.not(state: 'closed').where('updated_at < ?', Time.zone.now - diff).each {|chat_session|
      return if chat_session.recipients_active?
      chat_session.state = 'closed'
      chat_session.save
      message = {
        event: 'chat_session_closed',
        data: {
          session_id: chat_session.session_id,
          realname: 'System',
        },
      }
      chat_session.send_to_recipients(message)
    }
    true
  end

end
