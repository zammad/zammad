# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Chat::Session < ApplicationModel
  include HasSearchIndexBackend
  include CanSelector
  include HasTags

  include Chat::Session::Search
  include Chat::Session::SearchIndex
  include Chat::Session::Assets
  include Chat::Session::TriggersSubscriptions

  # rubocop:disable Rails/InverseOf
  has_many   :messages, class_name: 'Chat::Message', foreign_key: 'chat_session_id', dependent: :delete_all
  belongs_to :user,     class_name: 'User', optional: true
  belongs_to :chat,     class_name: 'Chat'
  # rubocop:enable Rails/InverseOf

  before_create :generate_session_id

  store :preferences

  def agent_user
    return if user_id.blank?

    user = User.lookup(id: user_id)
    return if user.blank?

    fullname = user.fullname
    chat_preferences = user.preferences[:chat] || {}
    if chat_preferences[:alternative_name].present?
      fullname = chat_preferences[:alternative_name]
    end
    url = nil
    if user.image && user.image != 'none' && chat_preferences[:avatar_state] != 'disabled'
      url = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/api/v1/users/image/#{user.image}"
    end
    {
      name:   fullname,
      avatar: url,
    }
  end

  def generate_session_id
    self.session_id = Digest::MD5.hexdigest(SecureRandom.uuid)
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

  # A running session also needs its agent: a legacy client in the old UI, a fresh heartbeat in the new
  #   one. Any other session lives while two participants are connected.
  def recipients_active?
    return true if !preferences
    return true if !preferences[:participants]

    connected = preferences[:participants].select { |client_id| Sessions.session_exists?(client_id) }

    return connected.size >= 2 if state != 'running' || user_id.blank?

    # The widget of the customer connects without a user. The client of an agent who transferred the
    #   session stays among the participants and is neither.
    client_user_ids = connected.map { |client_id| Sessions.get(client_id)&.dig(:user, 'id') }

    customer_connected = client_user_ids.any?(&:blank?)
    agent_connected    = client_user_ids.any? { |client_user_id| client_user_id.to_i == user_id }

    customer_connected && (agent_connected || ::Chat::Agent.beating?(user_id))
  end

  def send_to_recipients(message, ignore_client_id = nil)
    preferences[:participants].each do |local_client_id|
      next if local_client_id == ignore_client_id

      Sessions.send(local_client_id, message)
    end

    trigger_subscriptions(message)

    true
  end

  # Hands the oldest waiting session of the topics to the agent. The database decides a race: the
  #   conditional update changes a row for one claimant only, the others go on to the next candidate.
  def self.claim_next(chat_ids, user)
    where(state: 'waiting', chat_id: chat_ids).reorder(created_at: :asc).pluck(:id).each do |candidate_id|
      claimed = where(id: candidate_id, state: 'waiting', chat_id: chat_ids)
        .update_all(user_id: user.id, state: 'running', updated_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
      next if claimed.zero?

      return find(candidate_id)
    end

    nil
  end

  # The claim runs no callbacks, so a caller that does not save the session afterwards calls this.
  def search_index_update_after_claim
    return if !SearchIndexBackend.enabled?

    SearchIndexJob.perform_later(self.class.to_s, id)
    SearchIndexAssociationsJob.perform_later(self.class.to_s, id)
  end

  # Whether the agent runs this session at the moment: a waiting session keeps its agent after a transfer.
  def running_for?(user)
    state == 'running' && user_id == user.id
  end

  # A transferred conversation is underway for the customer already, who needs neither the start of
  #   an agent nor a greeting.
  def conversation_underway?
    messages.exists?
  end

  # Tells the widget which agent answers, unless the conversation is underway; answers whether it did.
  def send_start_to_customer(ignore_client_id = nil)
    return false if conversation_underway?

    send_to_recipients(
      {
        event: 'chat_session_start',
        data:  {
          state:      'ok',
          agent:      agent_user,
          session_id: session_id,
          chat_id:    chat_id,
        },
      },
      ignore_client_id,
    )
  end

  def position
    return if state != 'waiting'

    position = 0
    Chat::Session.where(state: 'waiting').reorder(created_at: :asc).each do |chat_session|
      position += 1
      break if chat_session.id == id
    end
    position
  end

  def self.messages_by_session_id(session_id)
    chat_session = Chat::Session.find_by(session_id: session_id)
    return if !chat_session

    chat_session
      .messages
      .reorder(created_at: :asc)
      .map(&:attributes)
  end

  def self.active_chats_by_user_id(user_id)
    actice_sessions = []
    Chat::Session.where(state: 'running', user_id: user_id).reorder(created_at: :asc).each do |session|
      session_attributes = session.attributes
      session_attributes['messages'] = []
      Chat::Message.where(chat_session_id: session.id).reorder(created_at: :asc).each do |message|
        session_attributes['messages'].push message.attributes
      end
      actice_sessions.push session_attributes
    end
    actice_sessions
  end
end
