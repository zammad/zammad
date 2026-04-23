# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class LongPollingController < ApplicationController
  skip_before_action :session_update # prevent race conditions
  prepend_before_action :authentication_check_only

  # GET /api/v1/message_send
  def message_send
    new_connection = false

    # check client id
    client_id = client_id_verify
    if !client_id
      new_connection = true
      client_id = client_id_gen
      log 'new client connection', client_id
    end
    data = params['data'].permit!.to_h
    session_data = {}
    if current_user&.id
      session_data = { 'id' => current_user.id }
    end

    if data['event'] == 'login'
      Sessions.create(client_id, session_data, { type: 'ajax' })
    elsif data['event']
      message = Sessions::Event.run(
        event:     data['event'],
        payload:   data,
        session:   session_data,
        client_id: client_id,
        clients:   {},
        options:   {},
      )
      if message
        Sessions.send(client_id, message)
      end
    else
      log "unknown message '#{data.inspect}'", client_id
    end

    if new_connection
      result = { client_id: client_id }
      render json: result
      return
    end
    render json: {}
  end

  # GET /api/v1/message_receive
  def message_receive
    client_id = client_id_verify
    raise Exceptions::UnprocessableEntity, __('Invalid client_id received!') if !client_id

    begin
      Sessions.touch(client_id) # rubocop:disable Rails/SkipsModelValidations

      queue = Sessions.queue(client_id)
      return render json: { event: 'pong' } if queue.blank?

      logger.debug { "send #{queue.inspect} to #{client_id}" }
      render json: queue
    rescue
      raise Exceptions::UnprocessableEntity, __('Invalid client_id in receive loop!')
    end
  end

  private

  def client_id_gen
    SecureRandom.uuid
  end

  def client_id_verify
    return if !params[:client_id]

    sessions = Sessions.sessions
    return if sessions.exclude?(params[:client_id].to_s)

    params[:client_id].to_s
  end

  def log(data, client_id = '-')
    logger.info "client(#{client_id}) #{data}"
  end
end
