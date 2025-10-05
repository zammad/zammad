# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketApprovalsController < ApplicationController
  before_action :authenticate_and_authorize!
  before_action :set_ticket
  before_action :check_permissions
  before_action :set_approval, only: %i[approve reject update destroy]

  def index
    approvals = Service::Ticket::Approval::List
      .new(current_user:)
      .execute(ticket: @ticket)

    render json: { approvals: approvals.map { |approval| serialize_approval(approval) } }
  end

  def create
    approval = Service::Ticket::Approval::Create
      .new(current_user:)
      .execute(
        ticket:      @ticket,
        approver_id: approval_create_params[:approver_id],
        message:     approval_create_params[:message],
        priority:    approval_create_params[:priority]
      )

    # Online notifications are handled by Transaction::ApprovalNotification

    render json: { approval: serialize_approval(approval) }, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: __('Approver not found') }, status: :not_found
  rescue Exceptions::UnprocessableEntity => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def approve
    approval = Service::Ticket::Approval::Decision
      .new(current_user:)
      .execute(approval: @approval, decision: :approve)

    apply_tag_changes(approval, :approved)

    # Online notifications are handled by Transaction::ApprovalNotification

    render json: { approval: serialize_approval(approval) }
  rescue Exceptions::Forbidden => e
    render json: { error: e.message }, status: :forbidden
  rescue Exceptions::UnprocessableEntity => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def reject
    approval = Service::Ticket::Approval::Decision
      .new(current_user:)
      .execute(approval: @approval, decision: :reject)

    apply_tag_changes(approval, :rejected)

    # Online notifications are handled by Transaction::ApprovalNotification

    render json: { approval: serialize_approval(approval) }
  rescue Exceptions::Forbidden => e
    render json: { error: e.message }, status: :forbidden
  rescue Exceptions::UnprocessableEntity => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    approval = Service::Ticket::Approval::Update
      .new(current_user:)
      .execute(approval: @approval, attributes: approval_update_params)

    # Online notifications are handled by Transaction::ApprovalNotification

    render json: { approval: serialize_approval(approval) }
  rescue Exceptions::Forbidden => e
    render json: { error: e.message }, status: :forbidden
  rescue Exceptions::UnprocessableEntity => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    serialized = Service::Ticket::Approval::Destroy
      .new(current_user:)
      .execute(approval: @approval)

    remove_decision_tags(serialized[:status])

    # Online notifications are handled by Transaction::ApprovalNotification

    render json: { success: true, approval: serialize_approval(serialized) }
  rescue Exceptions::Forbidden => e
    render json: { error: e.message }, status: :forbidden
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:ticket_id])
  end

  def set_approval
    @approval = @ticket.approvals.find(params[:id])
  end

  def check_permissions
    authorize!(@ticket, :show?)
  end

  def approval_create_params
    params.permit(:approver_id, :message, :priority)
  end

  def approval_update_params
    params.permit(:message, :priority)
  end

  def serialize_approval(approval)
    approver_id = approval.respond_to?(:approver_id) ? approval.approver_id : approval[:approver_id]
    requester_id = approval.respond_to?(:requester_id) ? approval.requester_id : approval[:requester_id]

    {
      id:           stringify_id(approval[:id] || approval.id),
      ticket_id:    stringify_id(approval[:ticket_id] || approval.ticket_id),
      status:       approval[:status] || approval.status,
      message:      approval[:message] || approval.message,
      priority:     approval[:priority] || approval.priority,
      approver:     approval.respond_to?(:approver) ? approval.approver&.fullname : approval[:approver],
      approver_id:  stringify_id(approver_id),
      requester:    approval.respond_to?(:requester) ? approval.requester&.fullname : approval[:requester],
      requester_id: stringify_id(requester_id),
      created_at:   approval[:created_at] || approval.created_at,
      updated_at:   approval[:updated_at] || approval.updated_at
    }
  end

  def notify_user(user_id:, notification:)
    return if user_id.blank?
    return if current_user && user_id.to_s == current_user.id.to_s

    OnlineNotification.add(
      type:          notification,
      object:        'Ticket',
      o_id:          @ticket.id,
      seen:          false,
      user_id:       user_id,
      created_by_id: current_user.id,
    )
  rescue StandardError
    nil
  end

  def apply_tag_changes(approval, decision)
    case decision
    when :approved
      @ticket.tag_remove('rejected', current_user.id) if @ticket.tag_list.include?('rejected')
      @ticket.tag_add('approved', current_user.id)
    when :rejected
      @ticket.tag_remove('approved', current_user.id) if @ticket.tag_list.include?('approved')
      @ticket.tag_add('rejected', current_user.id)
    end
  end

  def remove_decision_tags(status)
    case status
    when 'approved'
      @ticket.tag_remove('approved', current_user.id) if @ticket.tag_list.include?('approved')
    when 'rejected'
      @ticket.tag_remove('rejected', current_user.id) if @ticket.tag_list.include?('rejected')
    end
  end

  def stringify_id(value)
    value.present? ? value.to_s : nil
  end
end
