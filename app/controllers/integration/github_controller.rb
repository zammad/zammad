# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Integration::GitHubController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def verify
    github = ::GitHub.new(endpoint: params[:endpoint], api_token: params[:api_token])

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
    issue_tracker_list_service = if params[:ticket_id]
                                   Service::Ticket::ExternalReferences::IssueTracker::TicketList.new(
                                     type:   'github',
                                     ticket: Ticket.find(params[:ticket_id]),
                                   )
                                 else
                                   Service::Ticket::ExternalReferences::IssueTracker::FetchMetadata.new(
                                     type:        'github',
                                     issue_links: params[:links],
                                   )
                                 end

    render json: {
      result:   'ok',
      response: issue_tracker_list_service.execute,
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
