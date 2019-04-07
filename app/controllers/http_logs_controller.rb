# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class HttpLogsController < ApplicationController
  prepend_before_action :authentication_check

  # GET /http_logs/:facility
  def index
    permission_check('admin.*')
    list = if params[:facility]
             HttpLog.where(facility: params[:facility]).order(created_at: :desc).limit(params[:limit] || 50)
           else
             HttpLog.order(created_at: :desc).limit(params[:limit] || 50)
           end
    model_index_render_result(list)
  end

  # POST /http_logs
  def create
    permission_check('admin.*')
    model_create_render(HttpLog, params)
  end

end
