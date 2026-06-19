# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Integration::IdoitController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  SENSITIVE_FIELDS = [:api_token].freeze

  def verify
    unmasked_params = unmask_sensitive_params(params, Setting.get('idoit_config'))
    response = ::Idoit.verify(unmasked_params[:method], unmasked_params[:api_token], unmasked_params[:endpoint], unmasked_params[:username], unmasked_params[:password],
                              unmasked_params[:client_id], verify_ssl: unmasked_params[:verify_ssl])
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

  def query
    response = ::Idoit.query(params[:method], params[:filter])
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
    params[:object_ids] ||= []
    ticket = Ticket.find(params[:ticket_id])
    ticket.with_lock do
      authorize!(ticket, :show?)
      ticket.preferences[:idoit] ||= {}
      ticket.preferences[:idoit][:object_ids] = Array(params[:object_ids]).uniq
      ticket.save!
    end

    render json: {
      result: 'ok',
    }
  end
end
