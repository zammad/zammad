# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class ImportZendeskController < ApplicationController

  def url_check
    return if setup_done_response

    # validate
    if params[:url].blank? || params[:url] !~ %r{^(http|https)://.+?$}
      render json: {
        result:  'invalid',
        message: __('The provided URL is invalid.'),
      }
      return
    end

    # connection test
    translation_map = {
      'No such file'                                              => __('The hostname could not be found.'),
      'getaddrinfo: nodename nor servname provided, or not known' => __('The hostname could not be found.'),
      '503 Service Temporarily Unavailable'                       => __('The hostname could not be found.'),
      'No route to host'                                          => __('There is no route to this host.'),
      'Connection refused'                                        => __('The connection was refused.'),
    }

    response = UserAgent.request(URI.join(params[:url], '/api/v2/users/me').to_s, verify_ssl: true)

    if !response.success?
      message_human = ''
      translation_map.each do |key, message|
        if response.error.to_s.match?(%r{#{Regexp.escape(key)}}i)
          message_human = message
        end
      end
      render json: {
        result:        'invalid',
        message_human: message_human,
        message:       response.error.to_s,
      }
      return
    end

    if response.header['x-zendesk-api-version'].blank?
      render json: {
        result:        'invalid',
        message_human: __('The hostname could not be found.'),
      }
      return
    end

    endpoint = "#{params[:url]}/api/v2"
    endpoint.gsub!(%r{([^:])//+}, '\\1/')

    Setting.set('import_zendesk_endpoint', endpoint)

    render json: {
      result: 'ok',
      url:    params[:url],
    }
  end

  def credentials_check
    return if setup_done_response

    if !params[:username] || !params[:token]

      render json: {
        result:        'invalid',
        message_human: __('Incomplete credentials'),
      }
      return
    end

    Setting.set('import_zendesk_endpoint_username', params[:username])
    Setting.set('import_zendesk_endpoint_key', params[:token])

    result = Sequencer.process('Import::Zendesk::ConnectionTest')

    if !result[:connected]

      Setting.set('import_zendesk_endpoint_username', nil)
      Setting.set('import_zendesk_endpoint_key', nil)

      render json: {
        result:        'invalid',
        message_human: __('The provided credentials are invalid.'),
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

    job = ImportJob.create(name: 'Import::Zendesk')
    AsyncImportJob.perform_later(job)

    render json: {
      result: 'ok',
    }
  end

  def import_status
    job = ImportJob.find_by(name: 'Import::Zendesk')

    if job.finished_at.present?
      Setting.reload
    end

    model_show_render_item(job)
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
