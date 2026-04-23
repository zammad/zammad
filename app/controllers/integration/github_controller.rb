# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Integration::GitHubController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  SENSITIVE_FIELDS = [:api_token].freeze

  def verify
    unmasked_params = unmask_sensitive_params(params, Setting.get('github_config'))

    github = ::GitHub.new(endpoint: unmasked_params[:endpoint], api_token: unmasked_params[:api_token])

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
    response = if params[:ticket_id]
                 Service::Ticket::ExternalReferences::IssueTracker::TicketList.execute(
                   type:   'github',
                   ticket: Ticket.find(params[:ticket_id]),
                 )
               else
                 Service::Ticket::ExternalReferences::IssueTracker::FetchMetadata.execute(
                   type:        'github',
                   issue_links: params[:links],
                 )
               end

    render json: {
      result:   'ok',
      response: response,
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
      ticket.preferences[:github] ||= {}
      ticket.preferences[:github][:issue_links] = Array(params[:issue_links]).uniq
      ticket.save!
    end

    render json: {
      result: 'ok',
    }
  end
end
