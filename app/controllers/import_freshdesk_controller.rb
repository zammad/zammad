# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class ImportFreshdeskController < ApplicationController

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

    endpoint = "#{params[:url]}/api/v2"
    endpoint.gsub!(%r{([^:])//+}, '\\1/')

    response = UserAgent.request("#{endpoint}/contacts", verify_ssl: true)

    if response.header.nil? || !response.header['x-freshdesk-api-version']
      render json: {
        result:        'invalid',
        message_human: url_check_human_error_message(response.error.to_s),
        message:       response.error.to_s,
      }
      return
    end

    Setting.set('import_freshdesk_endpoint', endpoint)

    render json: {
      result: 'ok',
      url:    params[:url],
    }
  end

  def credentials_check
    return if setup_done_response

    if !params[:token]

      render json: {
        result:        'invalid',
        message_human: __('Incomplete credentials'),
      }
      return
    end

    Setting.set('import_freshdesk_endpoint_key', params[:token])

    connection_result = Sequencer.process('Import::Freshdesk::ConnectionTest')

    if !connection_result[:connected]

      Setting.set('import_freshdesk_endpoint_key', nil)

      render json: {
        result:        'invalid',
        message_human: __('The provided credentials are invalid.'),
      }
      return
    end

    permission_result = Sequencer.process('Import::Freshdesk::PermissionCheck')

    if !permission_result[:permission_present]

      Setting.set('import_freshdesk_endpoint_key', nil)

      render json: {
        result:        'invalid',
        message_human: __('You do not have administrator permission.'),
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
    Setting.set('import_backend', 'freshdesk')

    job = ImportJob.create(name: 'Import::Freshdesk')
    AsyncImportJob.perform_later(job)

    render json: {
      result: 'ok',
    }
  end

  def import_status
    job = ImportJob.find_by(name: 'Import::Freshdesk')

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

  def url_check_human_error_message(error)
    translation_map = {
      'No such file'                                              => __('The hostname could not be found.'),
      'getaddrinfo: nodename nor servname provided, or not known' => __('The hostname could not be found.'),
      'No route to host'                                          => __('There is no route to this host.'),
      'Connection refused'                                        => __('The connection was refused.'),
    }

    message_human = ''
    translation_map.each do |key, message|
      if error.match?(%r{#{Regexp.escape(key)}}i)
        message_human = message
      end
    end

    message_human
  end

end
