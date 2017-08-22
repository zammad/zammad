# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
require 'zendesk_api'

class ImportZendeskController < ApplicationController

  def url_check
    return if setup_done_response

    # validate
    if params[:url].blank? || params[:url] !~ %r{^(http|https)://.+?$}
      render json: {
        result: 'invalid',
        message: 'Invalid URL!',
      }
      return
    end

    # connection test
    translation_map = {
      'No such file'                                              => 'Hostname not found!',
      'getaddrinfo: nodename nor servname provided, or not known' => 'Hostname not found!',
      'No route to host'                                          => 'No route to host!',
      'Connection refused'                                        => 'Connection refused!',
    }

    response = UserAgent.request(params[:url])

    if !response.success?
      message_human = ''
      translation_map.each { |key, message|
        if response.error.to_s =~ /#{Regexp.escape(key)}/i
          message_human = message
        end
      }
      render json: {
        result: 'invalid',
        message_human: message_human,
        message: response.error.to_s,
      }
      return
    end

    # since 2016-10-15 a redirect to a marketing page has been implemented
    if response.body !~ /#{params[:url]}/
      render json: {
        result: 'invalid',
        message_human: 'Hostname not found!',
      }
      return
    end

    endpoint = "#{params[:url]}/api/v2"
    endpoint.gsub!(%r{([^:])//+}, '\\1/')
    Setting.set('import_zendesk_endpoint', endpoint)

    render json: {
      result: 'ok',
      url: params[:url],
    }
  end

  def credentials_check
    return if setup_done_response

    if !params[:username] || !params[:token]

      render json: {
        result: 'invalid',
        message_human: 'Incomplete credentials',
      }
      return
    end

    Setting.set('import_zendesk_endpoint_username', params[:username])
    Setting.set('import_zendesk_endpoint_key', params[:token])

    if !Import::Zendesk.connection_test

      Setting.set('import_zendesk_endpoint_username', nil)
      Setting.set('import_zendesk_endpoint_key', nil)

      render json: {
        result: 'invalid',
        message_human: 'Invalid credentials!',
      }
      return
    end

    render json: {
      result: 'ok',
    }
  end

  def import_start
    return if setup_done_response
    Setting.set('import_mode', true)
    Setting.set('import_backend', 'zendesk')

    # start migration
    Import::Zendesk.delay.start_bg

    render json: {
      result: 'ok',
    }
  end

  def import_status
    result = Import::Zendesk.status_bg
    if result[:result] == 'import_done'
      Setting.reload
    end
    render json: result
  end

  private

  def setup_done
    count = User.all.count()
    done = true
    if count <= 2
      done = false
    end
    done
  end

  def setup_done_response
    if !setup_done
      return false
    end
    render json: {
      setup_done: true,
    }
    true
  end

end
