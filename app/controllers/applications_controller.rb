# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ApplicationsController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  def index
    all = Doorkeeper::Application.all
    if response_full?
      assets = {}
      item_ids = []
      all.each do |item|
        item_ids.push item.id
        if !assets[:Application]
          assets[:Application] = {}
        end
        application = item.attributes
        application[:clients] = Doorkeeper::AccessToken.where(application_id: item.id).count
        assets[:Application][item.id] = application
      end
      render json: {
        record_ids: item_ids,
        assets:     assets,
      }, status: :ok
      return
    end

    render json: all, status: :ok
  end

  def token
    access_token = Doorkeeper::AccessToken.create!(application_id: params[:id], resource_owner_id: current_user.id)
    render json: { token: access_token.token }, status: :ok
  end

  def show
    application = Doorkeeper::Application.find(params[:id])
    render json: application, status: :ok
  end

  def create
    application = Doorkeeper::Application.new(clean_params)
    application.save!
    render json: application, status: :ok
  end

  def update
    application = Doorkeeper::Application.find(params[:id])
    application.update!(clean_params)
    render json: application, status: :ok
  end

  def destroy
    application = Doorkeeper::Application.find(params[:id])
    application.destroy!
    render json: {}, status: :ok
  end

  private

  def clean_params
    params_data = params.permit!.to_h
    params_data.delete('application')
    params_data.delete('action')
    params_data.delete('controller')
    params_data.delete('id')
    params_data.delete('uid')
    params_data.delete('secret')
    params_data.delete('created_at')
    params_data.delete('updated_at')
    params_data
  end
end
