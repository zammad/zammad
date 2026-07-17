# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class MentionsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  # GET /api/v1/mentions
  def index
    list = mentionable_object.mentions

    if response_full?
      item_ids = list.map(&:id)
      assets   = ApplicationModel::CanAssets.reduce list

      render json: {
        record_ids: item_ids,
        assets:     assets,
      }
      return
    end

    # return result
    render json: {
      mentions: list,
    }
  end

  # POST /api/v1/mentions
  def create
    target_user = if params[:user_id].present? && params[:user_id].to_i != current_user.id
                    User.find_by(id: params[:user_id])
                  else
                    current_user
                  end

    if target_user.nil?
      render json: { error: __('User not found.') }, status: :unprocessable_content
      return
    end

    if target_user.id != current_user.id && target_user.permissions?('ticket.agent')
      render json: { error: __('Agents cannot be added as participants.') }, status: :unprocessable_content
      return
    end

    if mentionable_object.is_a?(Ticket) && target_user.id == mentionable_object.customer_id
      render json: { error: __('The ticket customer is already a participant.') }, status: :unprocessable_content
      return
    end

    Mention.subscribe! mentionable_object, target_user

    render json: true, status: :created
  end

  # DELETE /api/v1/mentions
  def destroy
    mention = Mention.find_by(id: params[:id])

    if mention.nil?
      render json: { error: __('Mention not found.') }, status: :unprocessable_content
      return
    end

    # Self-removal or agent-removal (mirrors GraphQL ParticipantRemove)
    if mention.user_id != current_user.id
      if !current_user.permissions?('ticket.agent')
        render json: { error: __('You cannot remove this participant.') }, status: :forbidden
        return
      end
      ticket = Ticket.find_by(id: mention.mentionable_id)
      if !ticket || !TicketPolicy.new(current_user, ticket).agent_update_access?
        render json: { error: __('You cannot remove this participant.') }, status: :forbidden
        return
      end
    end

    mention.destroy!
    render json: true, status: :ok
  end

  def mentionable_object
    @mentionable_object ||= begin
      case params[:mentionable_type]
      when 'Ticket'
        Ticket.find_by id: params[:mentionable_id]
      else
        raise Exceptions::UnprocessableContent, __("The parameter 'mentionable_type' is invalid.")
      end
    end
  end
end
