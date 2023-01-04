# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Mention < ApplicationModel
  include ChecksClientNotification
  include HasHistory

  include Mention::Assets

  after_create :update_mentionable
  after_destroy :update_mentionable

  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'
  belongs_to :user, class_name: 'User'
  belongs_to :mentionable, polymorphic: true

  association_attributes_ignored :created_by, :updated_by
  client_notification_events_ignored :update, :touch

  validates_with Mention::Validation

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
    mentionable.update(updated_by: updated_by)
    mentionable.touch # rubocop:disable Rails/SkipsModelValidations
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
  def self.subscribe!(object, user)
    object
      .mentions
      .find_or_create_by! user: user

    true
  end

  # Unsubscribe a user from changes of an object
  # @param target to unsubscribe from
  # @param user
  # @return Boolean
  def self.unsubscribe!(object, user)
    object
      .mentions
      .find_by(user: user)
      &.destroy!

    true
  end

  # Check if given user is able to subscribe to a given object
  # @param object to subscribe to
  # @param mentioned user
  # @return Boolean
  def self.mentionable?(object, user)
    case object
    when Ticket
      TicketPolicy.new(user, object).agent_read_access?
    else
      false
    end
  end
end
