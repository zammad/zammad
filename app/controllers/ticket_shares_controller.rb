# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketSharesController < ApplicationController
  before_action :authenticate_and_authorize!
  before_action :set_ticket
  before_action :check_permissions
  before_action :set_share, only: %i[revoke update destroy]

  def index
    shares = Service::Ticket::Share::List
      .new(current_user:)
      .execute(ticket: @ticket)

    render json: { shares: shares.map { |share| serialize_share(share) } }
  end

  def create
    share = Service::Ticket::Share::Create
      .new(current_user:)
      .execute(
        ticket:     @ticket,
        group_id:   share_create_params[:group_id],
        message:    share_create_params[:message],
        expires_at: share_create_params[:expires_at]
      )

    # Online notifications are handled by Transaction::ShareNotification

    render json: { share: serialize_share(share) }, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: __('Group not found') }, status: :not_found
  rescue Exceptions::UnprocessableEntity => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def revoke
    share = Service::Ticket::Share::Revoke
      .new(current_user:)
      .execute(share: @share)

    # Online notifications are handled by Transaction::ShareNotification

    render json: { share: serialize_share(share) }
  rescue Exceptions::Forbidden => e
    render json: { error: e.message }, status: :forbidden
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    share = Service::Ticket::Share::Update
      .new(current_user:)
      .execute(share: @share, attributes: share_update_params)

    # Online notifications are handled by Transaction::ShareNotification

    render json: { share: serialize_share(share) }
  rescue Exceptions::Forbidden => e
    render json: { error: e.message }, status: :forbidden
  rescue Exceptions::UnprocessableEntity => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    share_data = Service::Ticket::Share::Destroy
      .new(current_user:)
      .execute(share: @share)

    # Online notifications are handled by Transaction::ShareNotification

    render json: { success: true, share: serialize_share(share_data) }
  rescue Exceptions::Forbidden => e
    render json: { error: e.message }, status: :forbidden
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:ticket_id])
  end

  def set_share
    @share = @ticket.shares.find(params[:id])
  end

  def check_permissions
    authorize!(@ticket, :show?)
  end

  def share_create_params
    params.permit(:group_id, :message, :expires_at)
  end

  def share_update_params
    params.permit(:message, :expires_at)
  end

  def serialize_share(share)
    group_id = extract_attribute(share, :group_id)
    group_name = extract_attribute(share, :group_name) || share.try(:group)&.fullname || share.try(:group)&.name

    {
      id:               stringify_id(extract_attribute(share, :id)),
      ticket_id:        stringify_id(extract_attribute(share, :ticket_id)),
      group_id:         stringify_id(group_id),
      group_name:       group_name,
      group:            group_name,
      shared_by_id:     stringify_id(extract_attribute(share, :shared_by_id)),
      shared_by_name:   share.respond_to?(:shared_by) ? share.shared_by&.fullname : share[:shared_by_name],
      permissions:      Array(extract_attribute(share, :permissions)),
      message:          extract_attribute(share, :message),
      status:           extract_attribute(share, :status),
      created_at:       extract_attribute(share, :created_at),
      updated_at:       extract_attribute(share, :updated_at),
      expires_at:       extract_attribute(share, :expires_at)
    }
  end

  def notify_shared_group(share_data, notification_type)
    group_id = extract_attribute(share_data, :group_id)
    return if group_id.blank?

    member_ids = group_member_ids(group_id)
    member_ids << extract_attribute(share_data, :shared_by_id)

    member_ids.compact.uniq.each do |user_id|
      next if user_id.to_i == current_user.id

      OnlineNotification.add(
        type:          notification_type,
        object:        'Ticket',
        o_id:          @ticket.id,
        seen:          false,
        user_id:       user_id,
        created_by_id: current_user.id,
      )
    end
  rescue StandardError => e
    Rails.logger.warn "Failed to create share notification: #{e.message}"
    nil
  end

  def group_member_ids(group_id)
    # Only include agents and admins, not customers
    group_users = Array(User.group_access(group_id, 'read')).select(&:active?)
    agent_users = group_users.select { |user| user.permissions?('ticket.agent') }
    agent_users.map(&:id)
  rescue StandardError => e
    Rails.logger.warn "Failed to resolve group members for share notification: #{e.message}"
    []
  end

  def extract_attribute(source, key)
    if source.respond_to?(key)
      source.public_send(key)
    elsif source.respond_to?(:[])
      source[key]
    end
  end

  def stringify_id(value)
    value.present? ? value.to_s : nil
  end
end


