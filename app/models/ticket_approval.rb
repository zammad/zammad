# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketApproval < ApplicationRecord
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
  belongs_to :approver, class_name: 'User'
  belongs_to :requester, class_name: 'User'

  # validations
  validates :ticket_id, presence: true
  validates :approver_id, presence: true
  validates :requester_id, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending approved rejected] }
  validates :priority, presence: true, inclusion: { in: %w[low normal high urgent] }

  # additional fields that might be added later
  attr_accessor :approved_at, :approved_by_id, :rejected_at, :rejected_by_id

  # scopes
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :for_ticket, ->(ticket_id) { where(ticket_id: ticket_id) }
  scope :for_approver, ->(user_id) { where(approver_id: user_id) }
  scope :for_requester, ->(user_id) { where(requester_id: user_id) }

  # callbacks
  before_create :set_defaults
  after_create :create_history_entry
  after_update :update_history_entry
  after_destroy :destroy_history_entry

  def set_defaults
    self.status ||= 'pending'
    self.priority ||= 'normal'
    self.created_at ||= Time.current
    self.updated_at ||= Time.current
  end

  def create_history_entry
    History.add(
      o_id:           id,
      history_type:   'created',
      history_object: 'TicketApproval',
      value_to:       "Approval request created for ticket ##{ticket.number}",
      created_by_id:  requester_id
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
      history_object: 'TicketApproval',
      value_to:       "Approval request updated: #{changes}",
      created_by_id:  User.current&.id || 1
    )
  end

  def destroy_history_entry
    History.add(
      o_id:           id,
      history_type:   'deleted',
      history_object: 'TicketApproval',
      value_to:       "Approval request deleted for ticket ##{ticket.number}",
      created_by_id:  User.current&.id || 1
    )
  end

  # instance methods
  def pending?
    status == 'pending'
  end

  def approved?
    status == 'approved'
  end

  def rejected?
    status == 'rejected'
  end

  def approve!(user = nil)
    update!(
      status: 'approved',
      approved_at: Time.current,
      approved_by_id: user&.id
    )
  end

  def reject!(user = nil)
    update!(
      status: 'rejected',
      rejected_at: Time.current,
      rejected_by_id: user&.id
    )
  end

  def approver_name
    approver&.fullname || 'Unknown'
  end

  def requester_name
    requester&.fullname || 'Unknown'
  end

  def to_s
    "Approval ##{id} for Ticket ##{ticket.number}"
  end

  # search index
  def search_index_attribute_lookup
    attributes = super
    attributes['ticket_number'] = ticket&.number
    attributes['approver_name'] = approver_name
    attributes['requester_name'] = requester_name
    attributes['status'] = status
    attributes['priority'] = priority
    attributes
  end

  # activity stream
  def activity_stream_permission
    'ticket.agent'
  end

  def activity_stream_attributes
    {
      ticket_id: ticket_id,
      approver_id: approver_id,
      requester_id: requester_id,
      status: status,
      priority: priority
    }
  end
end
