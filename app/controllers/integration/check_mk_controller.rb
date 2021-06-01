# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Integration::CheckMkController < ApplicationController
  skip_before_action :verify_csrf_token
  before_action :check_configured

  def update

    # check params
    raise Exceptions::UnprocessableEntity, 'event_id is missing!' if params[:event_id].blank?
    raise Exceptions::UnprocessableEntity, 'state is missing!' if params[:state].blank?
    raise Exceptions::UnprocessableEntity, 'host is missing!' if params[:host].blank?

    # search for open ticket
    auto_close = Setting.get('check_mk_auto_close')
    auto_close_state_id = Setting.get('check_mk_auto_close_state_id')
    group_id = Setting.get('check_mk_group_id')
    state_recovery_match = '(OK|UP)'

    # follow-up detection by meta data
    integration = 'check_mk'
    open_states = Ticket::State.by_category(:open)
    ticket_ids = Ticket.where(state: open_states).order(created_at: :desc).limit(5000).pluck(:id)
    ticket_ids_found = []
    ticket_ids.each do |ticket_id|
      ticket = Ticket.find_by(id: ticket_id)
      next if !ticket
      next if !ticket.preferences
      next if !ticket.preferences[integration]
      next if !ticket.preferences[integration]['host']
      next if ticket.preferences[integration]['host'] != params[:host]
      next if ticket.preferences[integration]['service'] != params[:service]

      # found open ticket for service+host
      ticket_ids_found.push ticket.id
    end

    # new ticket, set meta data
    title = "#{params[:host]} is #{params[:state]}"
    body = "EventID: #{params[:event_id]}
Host: #{params[:host]}
Service: #{params[:service] || '-'}
State: #{params[:state]}
Text: #{params[:text] || '-'}
RemoteIP: #{request.remote_ip}
UserAgent: #{request.env['HTTP_USER_AGENT'] || '-'}
"

    # add article
    if params[:state].present? && ticket_ids_found.present?
      ticket_ids_found.each do |ticket_id|
        ticket = Ticket.find_by(id: ticket_id)
        next if !ticket

        Ticket::Article.create!(
          ticket_id: ticket_id,
          type_id:   Ticket::Article::Type.find_by(name: 'web').id,
          sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
          body:      body,
          subject:   title,
          internal:  false,
        )
      end
      if (!auto_close && params[:state].match(%r{#{state_recovery_match}}i)) || !params[:state].match(%r{#{state_recovery_match}}i)
        render json: {
          result:     'ticket already open, added note',
          ticket_ids: ticket_ids_found,
        }
        return
      end
    end

    # check if service is recovered
    if auto_close && params[:state].present? && params[:state].match(%r{#{state_recovery_match}}i)
      if ticket_ids_found.blank?
        render json: {
          result: 'no open tickets found, ignore action',
        }
        return
      end
      ticket_ids_found.each do |ticket_id|
        ticket = Ticket.find_by(id: ticket_id)
        next if !ticket

        ticket.state_id = auto_close_state_id
        ticket.save!
      end
      render json: {
        result:     "closed tickets with ids #{ticket_ids_found.join(',')}",
        ticket_ids: ticket_ids_found,
      }
      return
    end

    # define customer of ticket
    customer = nil
    if params[:customer].present?
      customer = User.find_by(login: params[:customer].downcase)
      if !customer
        customer = User.find_by(email: params[:customer].downcase)
      end
    end
    if !customer
      customer = User.lookup(id: 1)
    end

    params[:state] = nil
    params[:customer] = nil
    ticket = Ticket.new(Ticket.param_cleanup(Ticket.association_name_to_id_convert(params)))
    ticket.group_id ||= group_id
    ticket.customer_id = customer.id
    ticket.title = title
    ticket.preferences = {
      check_mk: {
        host:    params[:host],
        service: params[:service],
      },
    }
    ticket.save!

    Ticket::Article.create!(
      ticket_id: ticket.id,
      type_id:   Ticket::Article::Type.find_by(name: 'web').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      body:      body,
      subject:   title,
      internal:  false,
    )

    render json: {
      result:        "new ticket created (ticket id: #{ticket.id})",
      ticket_id:     ticket.id,
      ticket_number: ticket.number,
    }
  end

  private

  def check_configured
    http_log_config facility: 'check_mk'

    if !Setting.get('check_mk_integration')
      raise Exceptions::UnprocessableEntity, 'Feature is disable, please contact your admin to enable it!'
    end

    if Setting.get('check_mk_token') != params[:token]
      raise Exceptions::UnprocessableEntity, 'Invalid token!'
    end

    true
  end

end
