# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ImportOtrsController < ApplicationController

  def url_check
    return if setup_done_response

    # validate
    if !params[:url] || params[:url] !~ %r{^(http|https)://.+?$}
      render json: {
        result: 'invalid',
        message: 'Invalid!',
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

    # try connecting to otrs
    response = UserAgent.request(params[:url])
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

    message_human = 'Host found, but it seems to be no OTRS installation!'
    suffixes = ['/public.pl', '/otrs/public.pl']
    suffixes.each {|suffix|
      url = params[:url] + suffix + '?Action=ZammadMigrator'
      # strip multible / in url
      url.gsub!(%r{([^:])(/+/)}, '\\1/')
      response = UserAgent.request( url )

      #Setting.set('import_mode', true)
      Setting.set('import_backend', 'otrs')
      Setting.set('import_otrs_endpoint', url)
      Setting.set('import_otrs_endpoint_key', '01234567899876543210')
      if response.body =~ /zammad migrator/
        render json: {
          url: url,
          result: 'ok',
        }
        return # rubocop:disable Lint/NonLocalExitFromIterator
      elsif response.body =~ /(otrs\sag|otrs.com|otrs.org)/i
        message_human = 'Host found, but no OTRS migrator is installed!'
      end
    }

    # return result
    render json: {
      result: 'invalid',
      message_human: message_human,
    }
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
    Import::OTRS.delay.start

    render json: {
      result: 'ok',
    }
  end

  def import_status
    return if setup_done_response

    state = Import::OTRS.current_state

    render json: {
      data: state,
      result: 'in_progress',
    }
  end

  private

  def setup_done
    return false
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
