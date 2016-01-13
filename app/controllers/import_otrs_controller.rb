# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ImportOtrsController < ApplicationController

  def url_check
    return if setup_done_response

    # validate
    if !params[:url] || params[:url] !~ %r{^(http|https)://.+?$}
      render json: {
        result: 'invalid',
        message: 'Invalid URL!',
      }
      return
    end

    # connection test
    translation_map = {
      'authentication failed'                                     => 'Authentication failed!',
      'getaddrinfo: nodename nor servname provided, or not known' => 'Hostname not found!',
      'No route to host'                                          => 'No route to host!',
      'Connection refused'                                        => 'Connection refused!',
    }

    response = UserAgent.request( params[:url] )

    if !response.success? && response.code.to_s !~ /^40.$/
      message_human = ''
      translation_map.each {|key, message|
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

    result = {}
    if response.body =~ /zammad migrator/

      migrator_response = JSON.parse(response.body)

      if migrator_response['Success'] == 1

        url_parts = params[:url].split(';')
        key_parts = url_parts[1].split('=')

        Setting.set('import_backend', 'otrs')
        Setting.set('import_otrs_endpoint', url_parts[0])
        Setting.set('import_otrs_endpoint_key', key_parts[1])

        result = {
          result: 'ok',
          url: params[:url],
        }
      else
        result = {
          result: 'invalid',
          message_human: migrator_response['Error']
        }
      end
    elsif response.body =~ /(otrs\sag|otrs\.com|otrs\.org)/i
      result = {
        result: 'invalid',
        message_human: 'Host found, but no OTRS migrator is installed!'
      }
    else
      result = {
        result: 'invalid',
        message_human: 'Host found, but it seems to be no OTRS installation!',
      }
    end

    render json: result
  end

  def import_start
    return if setup_done_response
    Setting.set('import_mode', true)
    welcome = Import::OTRS.connection_test
    if !welcome
      render json: {
        message: 'Migrator can\'t read OTRS output!',
        result: 'invalid',
      }
      return
    end

    # start migration
    Import::OTRS.delay.start_bg(
      import_otrs_endpoint: Setting.get('import_otrs_endpoint'),
      import_otrs_endpoint_key: Setting.get('import_otrs_endpoint_key'),
    )

    render json: {
      result: 'ok',
    }
  end

  def import_status
    result = Import::OTRS.status_bg
    if result[:setup_done] == true
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
