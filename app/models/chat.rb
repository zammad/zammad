# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Chat < ApplicationModel
  include ChecksHtmlSanitized

  validates :name, presence: true
  store     :preferences

  sanitized_html :note

=begin

get the customer state of a chat

  chat = Chat.find(123)
  chat.customer_state(session_id = nil)

returns

chat_disabled - chat is disabled

  {
    state: 'chat_disabled'
  }

returns (without session_id)

offline - no agent is online

  {
    state: 'offline'
  }

no_seats_available - no agent is available (all slots are used, max_queue is full)

  {
    state: 'no_seats_available'
  }

online - ready for chats

  {
    state: 'online'
  }

returns (session_id)

reconnect - position of waiting list for new chat

  {
    state:    'reconnect',
    position: chat_session.position,
  }

reconnect - chat session already exists, serve agent and session chat messages (to redraw chat history)

  {
    state:   'reconnect',
    session: session,
    agent:   user,
  }

=end

  def customer_state(session_id = nil)
    return { state: 'chat_disabled' } if !Setting.get('chat')

    # reconnect
    if session_id
      chat_session = Chat::Session.find_by(session_id: session_id, state: %w[waiting running])

      if chat_session
        case chat_session.state
        when 'running'
          user = chat_session.agent_user
          if user

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
        when 'waiting'
          return {
            state:    'reconnect',
            position: chat_session.position,
          }
        end
      end
    end

    # check if agents are available
    if Chat.active_agent_count([id]).zero?
      return { state: 'offline' }
    end

    # if all seads are used
    waiting_count = Chat.waiting_chat_count(id)
    if waiting_count >= max_queue
      return {
        state: 'no_seats_available',
        queue: waiting_count,
      }
    end

    # seads are available
    { state: 'online' }
  end

=begin

get available chat_ids for agent

  chat_ids = Chat.agent_active_chat_ids(User.find(123))

returns

  [1, 2, 3]

=end

  def self.agent_active_chat_ids(user)
    return [] if user.preferences[:chat].blank?
    return [] if user.preferences[:chat][:active].blank?

    chat_ids = []
    user.preferences[:chat][:active].each do |chat_id, state|
      next if state != 'on'

      chat_ids.push chat_id.to_i
    end
    return [] if chat_ids.blank?

    chat_ids
  end

=begin

get current agent state

  Chat.agent_state(123)

returns

  {
    state: 'chat_disabled'
  }

  {
    waiting_chat_count:        1,
    waiting_chat_session_list: [
      {
        id: 17,
        chat_id: 1,
        session_id: "81e58184385aabe92508eb9233200b5e",
        name: "",
        state: "waiting",
        user_id: nil,
        preferences: {
          "url: "http://localhost:3000/chat.html",
          "participants: ["70332537618180"],
          "remote_ip: nil,
          "geo_ip: nil,
          "dns_name: nil,
        },
        updated_by_id: nil,
        created_by_id: nil,
        created_at: Thu, 02 May 2019 10:10:45 UTC +00:00,
        updated_at: Thu, 02 May 2019 10:10:45 UTC +00:00},
      }
    ],
    running_chat_count:        0,
    running_chat_session_list: [],
    active_agent_count:        2,
    active_agent_ids:          [1, 2],
    seads_available:           5,
    seads_total:               15,
    active:                    true, # agent is available for chats
    assets:                    { ...related assets... },
  }

=end

  def self.agent_state(user_id)
    return { state: 'chat_disabled' } if !Setting.get('chat')

    current_user = User.lookup(id: user_id)
    return { error: "No such user with id: #{user_id}" } if !current_user

    chat_ids = agent_active_chat_ids(current_user)

    assets = {}
    Chat.where(active: true).each do |chat|
      assets = chat.assets(assets)
    end

    active_agent_ids = []
    active_agents(chat_ids).each do |user|
      active_agent_ids.push user.id
      assets = user.assets(assets)
    end

    running_chat_session_list_local = running_chat_session_list(chat_ids)

    running_chat_session_list_local.each do |session|
      next if !session['user_id']

      user = User.lookup(id: session['user_id'])
      next if !user

      assets = user.assets(assets)
    end

    {
      waiting_chat_count:                waiting_chat_count(chat_ids),
      waiting_chat_count_by_chat:        waiting_chat_count_by_chat(chat_ids),
      waiting_chat_session_list:         waiting_chat_session_list(chat_ids),
      waiting_chat_session_list_by_chat: waiting_chat_session_list_by_chat(chat_ids),
      running_chat_count:                running_chat_count(chat_ids),
      running_chat_session_list:         running_chat_session_list_local,
      active_agent_count:                active_agent_count(chat_ids),
      active_agent_ids:                  active_agent_ids,
      seads_available:                   seads_available(chat_ids),
      seads_total:                       seads_total(chat_ids),
      active:                            Chat::Agent.state(user_id),
      assets:                            assets,
    }
  end

=begin

check if agent is available for chat_ids

  chat_ids = Chat.agent_active_chat?(User.find(123), [1, 2])

returns

  true|false

=end

  def self.agent_active_chat?(user, chat_ids)
    return true if user.preferences[:chat].blank?
    return true if user.preferences[:chat][:active].blank?

    chat_ids.each do |chat_id|
      return true if user.preferences[:chat][:active][chat_id] == 'on' || user.preferences[:chat][:active][chat_id.to_s] == 'on'
    end
    false
  end

=begin

list all active sessins by user_id

  Chat.agent_state_with_sessions(123)

returns

  the same as Chat.agent_state(123) but with the following addition

 active_sessions: [
  {
    id: 19,
    chat_id: 1,
    session_id: "f28b2704e381c668c9b59215e9481310",
    name: "",
    state: "running",
    user_id: 3,
    preferences: {
      url: "http://localhost/chat.html",
      participants: ["70332475730240", "70332481108980"],
      remote_ip: nil,
      geo_ip: nil,
      dns_name: nil
    },
    updated_by_id: nil,
    created_by_id: nil,
    created_at: Thu, 02 May 2019 11:48:25 UTC +00:00,
    updated_at: Thu, 02 May 2019 11:48:29 UTC +00:00,
    messages: []
  }
]

=end

  def self.agent_state_with_sessions(user_id)
    return { state: 'chat_disabled' } if !Setting.get('chat')

    result = agent_state(user_id)
    result[:active_sessions] = Chat::Session.active_chats_by_user_id(user_id)
    result
  end

=begin

get count if waiting sessions in given chats

  Chat.waiting_chat_count(chat_ids)

returns

  123

=end

  def self.waiting_chat_count(chat_ids)
    Chat::Session.where(state: ['waiting'], chat_id: chat_ids).count
  end

  def self.waiting_chat_count_by_chat(chat_ids)
    list = {}
    Chat.where(active: true, id: chat_ids).pluck(:id).each do |chat_id|
      list[chat_id] = Chat::Session.where(chat_id: chat_id, state: ['waiting']).count
    end
    list
  end

  def self.waiting_chat_session_list(chat_ids)
    sessions = []
    Chat::Session.where(state: ['waiting'], chat_id: chat_ids).each do |session|
      sessions.push session.attributes
    end
    sessions
  end

  def self.waiting_chat_session_list_by_chat(chat_ids)
    sessions = {}
    Chat.where(active: true, id: chat_ids).pluck(:id).each do |chat_id|
      Chat::Session.where(chat_id: chat_id, state: ['waiting']).each do |session|
        sessions[chat_id] ||= []
        sessions[chat_id].push session.attributes
      end
    end
    sessions
  end

=begin

get count running sessions in given chats

  Chat.running_chat_count(chat_ids)

returns

  123

=end

  def self.running_chat_count(chat_ids)
    Chat::Session.where(state: ['running'], chat_id: chat_ids).count
  end

  def self.running_chat_session_list(chat_ids)
    sessions = []
    Chat::Session.where(state: ['running'], chat_id: chat_ids).each do |session|
      sessions.push session.attributes
    end
    sessions
  end

=begin

get count of active sessions in given chats

  Chat.active_chat_count(chat_ids)

returns

  123

=end

  def self.active_chat_count(chat_ids)
    Chat::Session.where(state: %w[waiting running], chat_id: chat_ids).count
  end

=begin

get user agents with concurrent

  Chat.available_agents_with_concurrent(chat_ids)

returns

  {
    123: 5,
    124: 1,
    125: 2,
  }

=end

  def self.available_agents_with_concurrent(chat_ids, diff = 2.minutes)
    agents = {}
    Chat::Agent.where(active: true).where('updated_at > ?', Time.zone.now - diff).each do |record|
      user = User.lookup(id: record.updated_by_id)
      next if !user
      next if !agent_active_chat?(user, chat_ids)

      agents[record.updated_by_id] = record.concurrent
    end
    agents
  end

=begin

get count of active agents in given chats

  Chat.active_agent_count(chat_ids)

returns

  123

=end

  def self.active_agent_count(chat_ids, diff = 2.minutes)
    count = 0
    Chat::Agent.where(active: true).where('updated_at > ?', Time.zone.now - diff).each do |record|
      user = User.lookup(id: record.updated_by_id)
      next if !user
      next if !agent_active_chat?(user, chat_ids)

      count += 1
    end
    count
  end

=begin

get active agents in given chats

  Chat.active_agent_count(chat_ids)

returns

  [User.find(123), User.find(345)]

=end

  def self.active_agents(chat_ids, diff = 2.minutes)
    users = []
    Chat::Agent.where(active: true).where('updated_at > ?', Time.zone.now - diff).each do |record|
      user = User.lookup(id: record.updated_by_id)
      next if !user
      next if !agent_active_chat?(user, chat_ids)

      users.push user
    end
    users
  end

=begin

get count all possible seads (possible chat sessions) in given chats

  Chat.seads_total(chat_ids)

returns

  123

=end

  def self.seads_total(chat_ids, diff = 2.minutes)
    total = 0
    available_agents_with_concurrent(chat_ids, diff).each_value do |concurrent|
      total += concurrent
    end
    total
  end

=begin

get count all available seads (available chat sessions) in given chats

  Chat.seads_available(chat_ids)

returns

  123

=end

  def self.seads_available(chat_ids, diff = 2.minutes)
    seads_total(chat_ids, diff) - active_chat_count(chat_ids)
  end

=begin

broadcast new agent status to all agents

  Chat.broadcast_agent_state_update(chat_ids)

optional you can ignore it for dedicated user

  Chat.broadcast_agent_state_update(chat_ids, ignore_user_id)

=end

  def self.broadcast_agent_state_update(chat_ids, ignore_user_id = nil)

    # send broadcast to agents
    Chat::Agent.where('active = ? OR updated_at > ?', true, Time.zone.now - 8.hours).each do |item|
      next if item.updated_by_id == ignore_user_id

      user = User.lookup(id: item.updated_by_id)
      next if !user
      next if !agent_active_chat?(user, chat_ids)

      data = {
        event: 'chat_status_agent',
        data:  Chat.agent_state(item.updated_by_id),
      }
      Sessions.send_to(item.updated_by_id, data)
    end
  end

=begin

broadcast new customer queue position to all waiting customers

  Chat.broadcast_customer_state_update(chat_id)

=end

  def self.broadcast_customer_state_update(chat_id)

    # send position update to other waiting sessions
    position = 0
    Chat::Session.where(state: 'waiting', chat_id: chat_id).order(created_at: :asc).each do |local_chat_session|
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

  Chat.cleanup(12.months)

=end

  def self.cleanup(diff = 12.months)
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
      return true if ip.match?(%r{#{local_ip.strip.gsub(%r{\*}, '.+?')}})
    end
    false
  end

=begin

check if website is allowed for chat

  chat = Chat.find(123)
  chat.website_whitelisted?('zammad.org')

=end

  def website_whitelisted?(website)
    return true if whitelisted_websites.blank?

    whitelisted_websites.split(';').any? do |whitelisted_website|
      website.downcase.include?(whitelisted_website.downcase.strip)
    end
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
    countries.any?(geo_ip['country_code'])
  end

end
