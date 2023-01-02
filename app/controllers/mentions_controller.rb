# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class MentionsController < ApplicationController
  prepend_before_action -> { authorize! }
  prepend_before_action { authentication_check }

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
    success = Mention.create!(
      mentionable: mentionable_object,
      user:        current_user,
    )
    if success
      render json: success, status: :created
    else
      render json: success.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/mentions
  def destroy
    success = Mention.find_by(user: current_user, id: params[:id]).destroy
    if success
      render json: success, status: :ok
    else
      render json: success.errors, status: :unprocessable_entity
    end
  end

  def mentionable_object
    @mentionable_object ||= begin
      case params[:mentionable_type]
      when 'Ticket'
        Ticket.find_by id: params[:mentionable_id]
      else
        raise Exceptions::UnprocessableEntity, __("The parameter 'mentionable_type' is invalid.")
      end
    end
  end
end
