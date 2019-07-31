# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Chat < ApplicationModel
  validates :name, presence: true
  store     :preferences

  def customer_state(session_id = nil)
    return { state: 'chat_disabled' } if !Setting.get('chat')

    # reconnect
    if session_id
      chat_session = Chat::Session.find_by(session_id: session_id, state: %w[waiting running])

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
              name:   chat_user.fullname,
              avatar: url,
            }

            # get queue position if needed
            session = Chat::Session.messages_by_session_id(session_id)
            if session
              return {
                state:   'reconnect',
                session: session,
                agent:   user,
              }
            end
          end
        elsif chat_session.state == 'waiting'
          return {
            state:    'reconnect',
            position: chat_session.position,
          }
        end
      end
    end

    # check if agents are available
    available_agents = Chat::Agent.where(active: true).where('updated_at > ?', Time.zone.now - 2.minutes).count
    if available_agents.zero?
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
    Chat.where(active: true).each do |chat|
      assets = chat.assets(assets)
    end
    active_agent_ids = []
    active_agents.each do |user|
      active_agent_ids.push user.id
      assets = user.assets(assets)
    end
    runningchat_session_list_local = running_chat_session_list
    runningchat_session_list_local.each do |session|
      next if !session['user_id']

      user = User.lookup(id: session['user_id'])
      next if !user

      assets = user.assets(assets)
    end
    {
      waiting_chat_count:        waiting_chat_count,
      waiting_chat_session_list: waiting_chat_session_list,
      running_chat_count:        running_chat_count,
      running_chat_session_list: runningchat_session_list_local,
      active_agent_count:        active_agent_count,
      active_agent_ids:          active_agent_ids,
      seads_available:           seads_available,
      seads_total:               seads_total,
      active:                    Chat::Agent.state(user_id),
      assets:                    assets,
    }
  end

  def self.agent_state_with_sessions(user_id)
    return { state: 'chat_disabled' } if !Setting.get('chat')

    result = agent_state(user_id)
    result[:active_sessions] = Chat::Session.active_chats_by_user_id(user_id)
    result
  end

  def self.waiting_chat_count
    Chat::Session.where(state: ['waiting']).count
  end

  def self.waiting_chat_session_list
    sessions = []
    Chat::Session.where(state: ['waiting']).each do |session|
      sessions.push session.attributes
    end
    sessions
  end

  def self.running_chat_count
    Chat::Session.where(state: ['running']).count
  end

  def self.running_chat_session_list
    sessions = []
    Chat::Session.where(state: ['running']).each do |session|
      sessions.push session.attributes
    end
    sessions
  end

  def self.active_chat_count
    Chat::Session.where(state: %w[waiting running]).count
  end

  def self.available_agents(diff = 2.minutes)
    agents = {}
    Chat::Agent.where(active: true).where('updated_at > ?', Time.zone.now - diff).each do |record|
      agents[record.updated_by_id] = record.concurrent
    end
    agents
  end

  def self.active_agent_count(diff = 2.minutes)
    Chat::Agent.where(active: true).where('updated_at > ?', Time.zone.now - diff).count
  end

  def self.active_agents(diff = 2.minutes)
    users = []
    Chat::Agent.where(active: true).where('updated_at > ?', Time.zone.now - diff).each do |record|
      user = User.lookup(id: record.updated_by_id)
      next if !user

      users.push user
    end
    users
  end

  def self.seads_total(diff = 2.minutes)
    total = 0
    available_agents(diff).each_value do |concurrent|
      total += concurrent
    end
    total
  end

  def self.seads_available(diff = 2.minutes)
    seads_total(diff) - active_chat_count
  end

=begin

broadcast new agent status to all agents

  Chat.broadcast_agent_state_update

optional you can ignore it for dedicated user

  Chat.broadcast_agent_state_update(ignore_user_id)

=end

  def self.broadcast_agent_state_update(ignore_user_id = nil)

    # send broadcast to agents
    Chat::Agent.where('active = ? OR updated_at > ?', true, Time.zone.now - 8.hours).each do |item|
      next if item.updated_by_id == ignore_user_id

      data = {
        event: 'chat_status_agent',
        data:  Chat.agent_state(item.updated_by_id),
      }
      Sessions.send_to(item.updated_by_id, data)
    end
  end

=begin

broadcast new customer queue position to all waiting customers

  Chat.broadcast_customer_state_update

=end

  def self.broadcast_customer_state_update

    # send position update to other waiting sessions
    position = 0
    Chat::Session.where(state: 'waiting').order(created_at: :asc).each do |local_chat_session|
      position += 1
      data = {
        event: 'chat_session_queue',
        data:  {
          state:      'queue',
          position:   position,
          session_id: local_chat_session.session_id,
        },
      }
      local_chat_session.send_to_recipients(data)
    end
  end

=begin

cleanup old chat messages

  Chat.cleanup

optional you can put the max oldest chat entries

  Chat.cleanup(3.months)

=end

  def self.cleanup(diff = 3.months)
    Chat::Session.where(state: 'closed').where('updated_at < ?', Time.zone.now - diff).each do |chat_session|
      Chat::Message.where(chat_session_id: chat_session.id).delete_all
      chat_session.destroy
    end

    true
  end

=begin

close chat sessions where participants are offline

  Chat.cleanup_close

optional you can put the max oldest chat sessions as argument

  Chat.cleanup_close(5.minutes)

=end

  def self.cleanup_close(diff = 5.minutes)
    Chat::Session.where.not(state: 'closed').where('updated_at < ?', Time.zone.now - diff).each do |chat_session|
      next if chat_session.recipients_active?

      chat_session.state = 'closed'
      chat_session.save
      message = {
        event: 'chat_session_closed',
        data:  {
          session_id: chat_session.session_id,
          realname:   'System',
        },
      }
      chat_session.send_to_recipients(message)
    end
    true
  end

=begin

check if ip address is blocked for chat

  chat = Chat.find(123)
  chat.blocked_ip?(ip)

=end

  def blocked_ip?(ip)
    return false if ip.blank?
    return false if block_ip.blank?

    ips = block_ip.split(';')
    ips.each do |local_ip|
      return true if ip == local_ip.strip
      return true if ip.match?(/#{local_ip.strip.gsub(/\*/, '.+?')}/)
    end
    false
  end

=begin

check if country is blocked for chat

  chat = Chat.find(123)
  chat.blocked_country?(ip)

=end

  def blocked_country?(ip)
    return false if ip.blank?
    return false if block_country.blank?

    geo_ip = Service::GeoIp.location(ip)
    return false if geo_ip.blank?
    return false if geo_ip['country_code'].blank?

    countries = block_country.split(';')
    countries.each do |local_country|
      return true if geo_ip['country_code'] == local_country
    end
    false
  end

end
