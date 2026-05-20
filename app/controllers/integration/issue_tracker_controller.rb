# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Integration::IssueTrackerController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  SENSITIVE_FIELDS = [:api_token].freeze

  def verify
    integration_client.verify!

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
                 ticket = Ticket.find(params[:ticket_id])
                 authorize!(ticket, :agent_read_access?)
                 Service::Ticket::ExternalReferences::IssueTracker::TicketList.execute(
                   type:   integration_type,
                   ticket: ticket,
                 )
               else
                 Service::Ticket::ExternalReferences::IssueTracker::FetchMetadata.execute(
                   type:        integration_type,
                   issue_links: params[:links],
                 )
               end

    render json: {
      result:   'ok',
      response: response,
    }
  rescue Pundit::NotAuthorizedError, ActiveRecord::RecordNotFound
    raise
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
      authorize!(ticket, :agent_read_access?)
      ticket.preferences[integration_type.to_sym] ||= {}
      ticket.preferences[integration_type.to_sym][:issue_links] = Array(params[:issue_links]).uniq
      ticket.save!
    end

    render json: {
      result: 'ok',
    }
  end

  private

  def integration_type
    raise NotImplementedError
  end

  def integration_client
    raise NotImplementedError
  end

  def unmasked_params
    @unmasked_params ||= unmask_sensitive_params(params, Setting.get("#{integration_type}_config"))
  end
end
