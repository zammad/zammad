# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ImportJiraController < ApplicationController

  def url_check
    return if setup_done_response

    if params[:url].blank? || params[:url] !~ %r{^https?://.+?$}
      render json: {
        result:  'invalid',
        message: __('The provided URL is invalid.'),
      }
      return
    end

    endpoint = params[:url].chomp('/')

    response = UserAgent.get("#{endpoint}/rest/api/3/serverInfo", {}, verify_ssl: true)

    if response.nil? || !response.success?
      render json: {
        result:        'invalid',
        message_human: url_check_human_error_message(response&.error.to_s),
        message:       response&.error.to_s,
      }
      return
    end

    Setting.set('import_jira_endpoint', endpoint)

    render json: {
      result: 'ok',
      url:    endpoint,
    }
  end

  def credentials_check
    return if setup_done_response

    if params[:email].blank? || params[:api_token].blank? || params[:project_key].blank?
      render json: {
        result:        'invalid',
        message_human: __('Incomplete credentials'),
      }
      return
    end

    store_credentials

    return if render_credentials_error(
      !Sequencer.process('Import::Jira::ConnectionTest')[:connected],
      __('The provided credentials are invalid.'),
    )

    return if render_credentials_error(
      !Sequencer.process('Import::Jira::PermissionCheck')[:permission_present],
      __('The account cannot browse the given Jira project.'),
    )

    render json: {
      result: 'ok',
    }
  end

  def import_start
    return if setup_done_response

    Setting.set('import_mode', true)
    Setting.set('import_backend', 'jira')

    ImportJob.create!(name: 'Import::Jira', start_after_creation: true)

    render json: {
      result: 'ok',
    }
  end

  def import_status
    job = ImportJob.find_by(name: 'Import::Jira')

    if job.nil?
      render json: { setup_done: true }
      return
    end

    if job.finished_at.present?
      Setting.reload

      render json: { setup_done: true }
      return
    end

    model_item_render(job)
  end

  private

  def store_credentials
    Setting.set('import_jira_email', params[:email])
    Setting.set('import_jira_api_token', params[:api_token])
    Setting.set('import_jira_project_key', params[:project_key])
  end

  def render_credentials_error(failed, message_human)
    return false if !failed

    reset_credentials

    render json: {
      result:        'invalid',
      message_human: message_human,
    }
    true
  end

  def reset_credentials
    Setting.set('import_jira_email', nil)
    Setting.set('import_jira_api_token', nil)
    Setting.set('import_jira_project_key', nil)
  end

  def setup_done
    count = User.count
    count > 2
  end

  def setup_done_response
    return false if !setup_done

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
