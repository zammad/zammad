# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Integration::IdoitController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  def verify
    response = ::Idoit.verify(params[:api_token], params[:endpoint], params[:client_id])
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
