# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Mention < ApplicationModel
  include HasDefaultModelUserRelations

  include ChecksClientNotification
  include HasHistory

  include Mention::Assets

  # used to forward the sourceable to the mention model
  # to keep track of added and removed mention by
  # postmaster filters, triggers and schedulers
  attr_accessor :sourceable

  after_create :update_mentionable
  after_destroy :update_mentionable

  belongs_to :user, class_name: 'User'
  belongs_to :mentionable, polymorphic: true

  association_attributes_ignored :created_by, :updated_by
  client_notification_events_ignored :update, :touch

  validates_with Validations::MentionValidator

  def notify_clients_data_attributes
    super.merge(
      'mentionable_id'   => mentionable_id,
      'mentionable_type' => mentionable_type,
    )
  end

  def history_log_attributes
    {
      related_o_id:           mentionable_id,
      related_history_object: mentionable_type,
      value_to:               user.id,
      sourceable:,
    }
  end

  def history_destroy
    history_log('removed', created_by_id)
  end

  def self.duplicates(mentionable1, mentionable2)
    Mention.joins(', mentions as mentionsb').where('
      mentions.user_id = mentionsb.user_id
      AND mentions.mentionable_type = ?
      AND mentions.mentionable_id = ?
      AND mentionsb.mentionable_type = ?
      AND mentionsb.mentionable_id = ?
    ', mentionable1.class.to_s, mentionable1.id, mentionable2.class.to_s, mentionable2.id)
  end

  def update_mentionable
    # make sure mentionable is touched even if updated_by value stays the same
    mentionable.update(updated_by: updated_by, updated_at: Time.current)
  end

  # Check if user is subscribed to given object
  # @param target to check against
  # @param user
  # @return Boolean
  def self.subscribed?(object, user)
    object.mentions.exists? user: user
  end

  # Subscribe a user to changes of an object
  # @param target to subscribe to
  # @param user
  # @return Boolean
  def self.subscribe!(object, user, sourceable: nil)
    # Best-effort cap on customer participants, no lock — acceptable for MVP
    if object.is_a?(Ticket) && Setting.get('ticket_participants_enabled')
      agent_user_ids = User.with_permissions('ticket.agent').pluck(:id)
      participant_count = object.mentions
        .joins(:user)
        .where(users: { active: true })
        .where.not(user_id: agent_user_ids)
        .count
      if participant_count >= 50 && !subscribed?(object, user)
        raise Exceptions::UnprocessableContent,
              __('Maximum of 50 participants per ticket reached.')
      end
    end

    is_new = !subscribed?(object, user)
    object.mentions.create!(user: user, sourceable: sourceable) if is_new
    if object.is_a?(Ticket) && is_new
      # Notify ONLY the newly added participant (not all existing recipients).
      # Uses the standard mailer pipeline but with participant_add flag to scope
      # recipients to the single new user instead of all group+mention users.
      item = {
        object:    object.class.name,
        object_id: object.id,
        type:      'update',
        user_id:   UserInfo.current_user_id || 1,
        changes:   { title: [object.title, object.title] },
      }
      begin
        Transaction::Notification.new(
          item,
          { participant_add: true, participant_add_user: user },
        ).perform
      rescue => e
        Rails.logger.warn "Participant notification delivery failed: #{e.message}"
      end
    end

    true
  end

  # Unsubscribe a user from changes of an object
  # @param target to unsubscribe from
  # @param user
  # @return Boolean
  def self.unsubscribe!(object, user, sourceable: nil)
    mention = object.mentions.find_by(user:)

    return true if mention.blank?

    mention.sourceable = sourceable
    mention.destroy!

    true
  end

  # Unsubscribe all users from changes of an object
  # @param target to unsubscribe from
  # @return Boolean
  def self.unsubscribe_all!(object, sourceable: nil)
    return object.mentions.destroy_all if sourceable.blank?

    object.mentions.all? do |mention|
      mention.sourceable = sourceable
      mention.destroy!
    end
  end

  # Check if given user is able to subscribe to a given object
  # @param object to subscribe to
  # @param mentioned user
  # @return Boolean
  def self.mentionable?(object, user)
    case object
    when Ticket
      policy = TicketPolicy.new(user, object)
      return true if policy.agent_read_access?
      return false if !Setting.get('ticket_participants_enabled')
      return false if !user.permissions?('ticket.customer')

      true
    else
      false
    end
  end
end
