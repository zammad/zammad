# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Integration::GitLabController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def verify
    gitlab = ::GitLab.new(params[:endpoint], params[:api_token], verify_ssl: params[:verify_ssl])

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

    gitlab = ::GitLab.new(config['endpoint'], config['api_token'], verify_ssl: config['verify_ssl'])

    if params[:links]
      render json: {
        result:   'ok',
        response: gitlab.issues_by_urls(params[:links]),
      }
    else
      render json: {
        result:   'ok',
        response: gitlab.issues_by_gids(params[:gids]),
      }
    end
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
      ticket.preferences[:gitlab][:gids] = Array(params[:gids]).uniq
      ticket.preferences[:gitlab][:issue_links] = Array(params[:issue_links]).uniq

      if Array(ticket.preferences[:gitlab][:issue_links]).uniq.empty?
        ticket.preferences[:gitlab].delete(:issue_links)
      end

      ticket.save!
    end

    render json: {
      result: 'ok',
    }
  end

end
