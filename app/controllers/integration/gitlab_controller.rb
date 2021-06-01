# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Integration::GitLabController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  def verify
    gitlab = ::GitLab.new(params[:endpoint], params[:api_token])

    gitlab.verify!

    render json: {
      result: 'ok',
    }
  rescue => e
    logger.error e

    render json: {
      result:  'failed',
      message: e.message,
    }
  end

  def query
    config = Setting.get('gitlab_config')

    gitlab = ::GitLab.new(config['endpoint'], config['api_token'])

    render json: {
      result:   'ok',
      response: gitlab.issues_by_urls(params[:links]),
    }
  rescue => e
    logger.error e

    render json: {
      result:  'failed',
      message: e.message,
    }
  end

  def update
    ticket = Ticket.find(params[:ticket_id])
    ticket.with_lock do
      authorize!(ticket, :show?)
      ticket.preferences[:gitlab] ||= {}
      ticket.preferences[:gitlab][:issue_links] = Array(params[:issue_links]).uniq
      ticket.save!
    end

    render json: {
      result: 'ok',
    }
  end

end
