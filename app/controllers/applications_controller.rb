# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ApplicationsController < ApplicationController
  before_action { authentication_check(permission: 'admin.api') }

  def index
    all = Doorkeeper::Application.all
    if params[:full]
      assets = {}
      item_ids = []
      all.each { |item|
        item_ids.push item.id
        if !assets[:Application]
          assets[:Application] = {}
        end
        assets[:Application][item.id] = item.attributes
      }
      render json: {
        record_ids: item_ids,
        assets: assets,
      }, status: :ok
      return
    end

    render json: all, status: :ok
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
    application.update_attributes!(clean_params)
    render json: application, status: :ok
  end

  def destroy
    application = Doorkeeper::Application.find(params[:id])
    application.destroy!
    render json: {}, status: :ok
  end

  private

  def clean_params
    params_data = params.permit! #.to_h
    params_data.delete('application')
    params_data.delete('action')
    params_data.delete('controller')
    params_data.delete('id')
    params_data.delete('uid')
    params_data.delete('secret')
    params_data.delete('created_at')
    params_data
  end
end
