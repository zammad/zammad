# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class MentionsController < ApplicationController
  prepend_before_action -> { authorize! }
  prepend_before_action { authentication_check }

  # GET /api/v1/mentions
  def list
    list = Mention.where(condition).order(created_at: :desc)

    if response_full?
      assets = {}
      item_ids = []
      list.each do |item|
        item_ids.push item.id
        assets = item.assets(assets)
      end
      render json: {
        record_ids: item_ids,
        assets:     assets,
      }, status: :ok
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
      mentionable: mentionable!,
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

  private

  def ensure_mentionable_type!
    return if ['Ticket'].include?(params[:mentionable_type])

    raise 'Invalid mentionable_type!'
  end

  def mentionable!
    ensure_mentionable_type!

    object = params[:mentionable_type].constantize.find(params[:mentionable_id])
    authorize!(object, :update?)
    object
  end

  def fill_condition_mentionable(condition)
    condition[:mentionable_type] = params[:mentionable_type]
    return if params[:mentionable_id].blank?

    condition[:mentionable_id] = params[:mentionable_id]
  end

  def fill_condition_id(condition)
    return if params[:id].blank?

    condition[:id] = params[:id]
  end

  def fill_condition_user(condition)
    return if params[:user_id].blank?

    condition[:user] = User.find(params[:user_id])
  end

  def condition
    condition = {}
    fill_condition_id(condition)
    fill_condition_user(condition)

    return condition if params[:mentionable_type].blank?

    mentionable!
    fill_condition_mentionable(condition)
    condition
  end
end
