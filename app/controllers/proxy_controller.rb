# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class ProxyController < ApplicationController
  prepend_before_action { authentication_check(permission: 'admin.system') }

  # POST /api/v1/proxy
  def test
    url = 'http://zammad.org'
    options = params
    options[:open_timeout] = 12
    options[:read_timeout] = 24
    begin
      result = UserAgent.get(
        url,
        {},
        options,
      )
    rescue => e
      render json: {
        result:  'failed',
        message: e.inspect
      }
      return
    end
    if result.success?
      render json: {
        result: 'success'
      }
      return
    end
    render json: {
      result:  'failed',
      message: result.body || result.error || result.code
    }
  end

end
