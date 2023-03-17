# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class UserAgentTestController < ApplicationController
  skip_before_action :verify_csrf_token

  # GET test/get
  def get
    process_request('get', 200)
  end

  # GET test/get_accepted
  def accepted
    process_request('get', 202)
  end

  # POST test/post
  def post
    process_request('post', 201)
  end

  # PUT test/put
  def put
    process_request('put', 200)
  end

  # DELETE test/delete
  def delete
    process_request('delete', 200)
  end

  # GET test/redirect
  def redirect
    redirect_to "#{request.protocol}#{request.host_with_port}/test/get/1?submitted=abc"
  end

  private

  def process_request(type, status)
    sleep_time = params[:sec].to_i > 1 ? params[:sec].to_i : 0.1
    sleep sleep_time

    render json:   {
             remote_ip:              request.remote_ip,
             content_type_requested: request.content_type,
             method:                 type,
             submitted:              params[:submitted]
           },
           status: status
  end
end
