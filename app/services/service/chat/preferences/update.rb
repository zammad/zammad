# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Writes the shape the old interface reads: string keys, 'on' for the topics taken, the greetings of a
#   topic joined by ';'. Preferences that are not given stay as they are.
class Service::Chat::Preferences::Update < Service::Base
  requires_current_user!

  MAX_WINDOWS = (1..20)

  attr_reader :max_windows, :alternative_name, :avatar_enabled, :topics

  # Topics are given as { topic: Chat, active: Boolean, phrases: [String] }; without phrases, the ones
  #   stored for the topic stay.
  def initialize(max_windows: nil, alternative_name: nil, avatar_enabled: nil, topics: nil)
    @max_windows      = max_windows
    @alternative_name = alternative_name
    @avatar_enabled   = avatar_enabled
    @topics           = topics
  end

  def execute
    validate_max_windows!

    previous_topic_ids = nil

    current_user.with_lock do
      previous_topic_ids = ::Chat.agent_active_chat_ids(current_user)
      current_user.preferences[:chat] = chat_preferences
      current_user.save!
    end

    current_user.reload
    announce_topics(previous_topic_ids) if topics

    current_user.preferences[:chat]
  end

  private

  # The agent's other windows learn their new queues. The agents of the topics left or taken count the
  #   agent only while the agent is available, so they are told only then.
  def announce_topics(previous_topic_ids)
    topic_ids    = ::Chat.agent_active_chat_ids(current_user)
    switched_off = switch_off_without_topic(topic_ids)

    return if !switched_off && topic_ids.sort == previous_topic_ids.sort

    counted        = switched_off || ::Chat::Agent.state(current_user.id)
    told_topic_ids = counted ? previous_topic_ids | topic_ids : []

    ::Chat.broadcast_agent_state_update(told_topic_ids, agent_ids: [current_user.id])
  end

  # Like the old interface: with no topic left to take chats for, the agent is unavailable. A topic the
  #   admin switched off still sits in the preferences, but takes no chats.
  def switch_off_without_topic(topic_ids)
    return false if ::Chat.exists?(active: true, id: topic_ids)
    return false if !::Chat::Agent.state(current_user.id)

    ::Chat::Agent.state(current_user.id, false)
  end

  def validate_max_windows!
    return if max_windows.nil? || MAX_WINDOWS.cover?(max_windows)

    raise Exceptions::UnprocessableContent, __('The number of concurrent chats must be between 1 and 20.')
  end

  def chat_preferences
    (current_user.preferences[:chat] || {}).to_h.deep_stringify_keys.tap do |chat|
      chat['max_windows']      = max_windows if max_windows
      chat['alternative_name'] = alternative_name if alternative_name
      chat['avatar_state']     = avatar_enabled ? 'enabled' : 'disabled' if !avatar_enabled.nil?

      topics&.each { |entry| apply_topic(chat, entry) }
    end
  end

  def apply_topic(chat, entry)
    key = entry[:topic].id.to_s

    chat['active'] = (chat['active'] || {}).stringify_keys.except(key)
    chat['active'][key] = 'on' if entry[:active]

    apply_phrases(chat, key, entry[:phrases]) if !entry[:phrases].nil?
  end

  def apply_phrases(chat, key, phrases)
    chat['phrase'] = (chat['phrase'] || {}).stringify_keys.except(key)
    # The old interface splits the stored greetings at the separator, so one inside a greeting would make two of it.
    phrase = phrases.map { |text| text.tr(::Chat::PHRASE_SEPARATOR, ',').strip }.compact_blank.join(::Chat::PHRASE_SEPARATOR)
    chat['phrase'][key] = phrase if phrase.present?
  end
end
