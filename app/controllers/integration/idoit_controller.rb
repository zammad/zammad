# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Integration::IdoitController < ApplicationController
  prepend_before_action -> { authentication_check(permission: ['agent.integration.idoit', 'admin.integration.idoit']) }, except: %i[verify query update]
  prepend_before_action -> { authentication_check(permission: ['admin.integration.idoit']) }, only: [:verify]
  prepend_before_action -> { authentication_check(permission: ['ticket.agent']) }, only: %i[query update]

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
      access!(ticket, 'read')
      ticket.preferences[:idoit] ||= {}
      ticket.preferences[:idoit][:object_ids] = Array(params[:object_ids]).uniq
      ticket.save!
    end

    render json: {
      result: 'ok',
    }
  end

end
