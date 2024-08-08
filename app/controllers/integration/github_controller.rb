# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Integration::GitHubController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def verify
    github = ::GitHub.new(params[:endpoint], params[:api_token])

    github.verify!

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
    config = Setting.get('github_config')

    github = ::GitHub.new(config['endpoint'], config['api_token'])

    if params[:links]
      render json: {
        result:   'ok',
        response: github.issues_by_urls(params[:links]),
      }
    else
      render json: {
        result:   'ok',
        response: github.issues_by_gids(params[:gids]),
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
      ticket.preferences[:github] ||= {}
      ticket.preferences[:github][:gids] = Array(params[:gids]).uniq
      ticket.preferences[:github][:issue_links] = Array(params[:issue_links]).uniq

      if Array(ticket.preferences[:github][:issue_links]).uniq.empty?
        ticket.preferences[:github].delete(:issue_links)
      end

      ticket.save!
    end

    render json: {
      result: 'ok',
    }
  end

end
