# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class HttpLogsController < ApplicationController
  before_action :authentication_check

  # GET /http_logs/:facility
  def index
    deny_if_not_role(Z_ROLENAME_ADMIN)
    list = if params[:facility]
             HttpLog.where(facility: params[:facility]).order('created_at DESC').limit(params[:limit] || 50)
           else
             HttpLog.order('created_at DESC').limit(params[:limit] || 50)
           end
    model_index_render_result(list)
  end

  # POST /http_logs
  def create
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(HttpLog, params)
  end

end
