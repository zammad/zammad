# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketShare < ApplicationModel
  include HasObjectManagerAttributes
  include HasSearchIndexBackend
  include CanBeImported
  include HasHistory
  include ChecksConditionValidation
  include HasActivityStreamLog
  include CanCsvImport
  include HasCollectionUpdate
  include HasTaskbars
  include HasTags

  # associations
  belongs_to :ticket, class_name: 'Ticket'
  belongs_to :group, class_name: 'Group'
  belongs_to :shared_by, class_name: 'User'

  # validations
  validates :ticket_id, presence: true
  validates :group_id, presence: true
  validates :shared_by_id, presence: true
  validates :status, presence: true, inclusion: { in: %w[active revoked deleted] }

  # additional fields that might be added later
  attr_accessor :revoked_at, :revoked_by_id

  # scopes
  scope :active, -> { where(status: 'active') }
  scope :revoked, -> { where(status: 'revoked') }
  scope :deleted, -> { where(status: 'deleted') }
  scope :for_ticket, ->(ticket_id) { where(ticket_id: ticket_id) }
  scope :for_group, ->(group_id) { where(group_id: group_id) }
  scope :for_user, ->(user_id) { where(shared_by_id: user_id) }
  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }

  # callbacks
  before_create :set_defaults
  after_create :create_history_entry
  after_update :update_history_entry
  after_destroy :destroy_history_entry

  def set_defaults
    self.status ||= 'active'
    self.created_at ||= Time.current
    self.updated_at ||= Time.current
  end

  def create_history_entry
    History.add(
      o_id:           id,
      history_type:   'created',
      history_object: 'TicketShare',
      value_to:       "Ticket ##{ticket.number} shared with group #{group_name}",
      created_by_id:  shared_by_id
    )
  end

  def update_history_entry
    return if saved_changes.empty?

    changes = saved_changes.map do |field, (old_value, new_value)|
      "#{field}: #{old_value} → #{new_value}"
    end.join(', ')

    History.add(
      o_id:           id,
      history_type:   'updated',
      history_object: 'TicketShare',
      value_to:       "Share updated: #{changes}",
      created_by_id:  User.current&.id || 1
    )
  end

  def destroy_history_entry
    History.add(
      o_id:           id,
      history_type:   'deleted',
      history_object: 'TicketShare',
      value_to:       "Share deleted for ticket ##{ticket.number}",
      created_by_id:  User.current&.id || 1
    )
  end

  # instance methods
  def active?
    status == 'active' && !expired?
  end

  def revoked?
    status == 'revoked'
  end

  def deleted?
    status == 'deleted'
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def revoke!(user = nil)
    update!(
      status: 'revoked',
      revoked_at: Time.current,
      revoked_by_id: user&.id
    )
  end

  def group_name
    group&.name || 'Unknown Group'
  end

  def shared_by_name
    shared_by&.fullname || 'Unknown User'
  end

  def to_s
    "Share ##{id} for Ticket ##{ticket.number} with #{group_name}"
  end

  # search index
  def search_index_attribute_lookup
    attributes = super
    attributes['ticket_number'] = ticket&.number
    attributes['group_name'] = group_name
    attributes['shared_by_name'] = shared_by_name
    attributes['status'] = status
    attributes['expires_at'] = expires_at
    attributes
  end

  # activity stream
  def activity_stream_permission
    'ticket.agent'
  end

  def activity_stream_attributes
    {
      ticket_id: ticket_id,
      group_id: group_id,
      shared_by_id: shared_by_id,
      status: status,
      expires_at: expires_at
    }
  end
end
