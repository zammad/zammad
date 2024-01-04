# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class HttpLogsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  # GET /http_logs/:facility
  def index
    list = if params[:facility]
             HttpLog.where(facility: params[:facility]).reorder(created_at: :desc).limit(params[:limit] || 50)
           else
             HttpLog.reorder(created_at: :desc).limit(params[:limit] || 50)
           end
    model_index_render_result(list)
  end

  # POST /http_logs
  def create
    model_create_render(HttpLog, params)
  end

end
