# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class HttpLogsController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  # GET /http_logs/:facility
  def index
    list = if params[:facility]
             HttpLog.where(facility: params[:facility]).order(created_at: :desc).limit(params[:limit] || 50)
           else
             HttpLog.order(created_at: :desc).limit(params[:limit] || 50)
           end
    model_index_render_result(list)
  end

  # POST /http_logs
  def create
    model_create_render(HttpLog, params)
  end

end
