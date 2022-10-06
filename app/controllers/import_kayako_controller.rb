# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class ImportKayakoController < ApplicationController
  def url_check
    return if setup_done_response

    url = params[:url]

    # validate
    if !valid_url_syntax?(url)
      render json: {
        result:  'invalid',
        message: __('The provided URL is invalid.'),
      }
      return
    end

    endpoint = build_endpoint_url(url)

    return if !valid_endpoint?(endpoint)

    Setting.set('import_kayako_endpoint', endpoint)

    render json: {
      result: 'ok',
      url:    url,
    }
  end

  def credentials_check # rubocop:disable Metrics/AbcSize
    return if setup_done_response

    if !params[:username] || !params[:password]
      render json: {
        result:        'invalid',
        message_human: __('Incomplete credentials'),
      }
      return
    end

    save_endpoint_settings(params[:username], params[:password])

    return if !valid_connection?

    render json: {
      result: 'ok',
    }
  end

  def import_start
    return if setup_done_response

    Setting.set('import_mode', true)
    Setting.set('import_backend', 'kayako')

    job = ImportJob.create(name: 'Import::Kayako')
    AsyncImportJob.perform_later(job)

    render json: {
      result: 'ok',
    }
  end

  def import_status
    job = ImportJob.find_by(name: 'Import::Kayako')

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

  def valid_url_syntax?(url)
    return false if url.blank? || url !~ %r{^(http|https)://.+?$}

    true
  end

  def valid_endpoint?(endpoint)
    response = UserAgent.request("#{endpoint}/teams", verify_ssl: true)

    if response.header.nil? || !response.header['x-api-version']
      render json: {
        result:        'invalid',
        message:       response.error.to_s,
        message_human: __('The hostname could not be found.'),
      }
      return false
    end

    true
  end

  def build_endpoint_url(url)
    endpoint = "#{url}/api/v1"
    endpoint.gsub(%r{([^:])//+}, '\\1/')
  end

  def valid_connection?
    result = Sequencer.process('Import::Kayako::ConnectionTest')

    if !result[:connected]
      reset_endpoint_settings

      render json: {
        result:        'invalid',
        message_human: __('The provided credentials are invalid.'),
      }
      return false
    end

    true
  end

  def save_endpoint_settings(username, possword)
    Setting.set('import_kayako_endpoint_username', username)
    Setting.set('import_kayako_endpoint_password', possword)
  end

  def reset_endpoint_settings
    save_endpoint_settings(nil, nil)
  end
end
