# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Cti::Driver::Base

  def initialize(params = {})
    @config = params[:config] || config
    @params = mapping(params[:params])
  end

  def mapping(params)
    params
  end

  def config
    {}
  end

  def process

    # validate directions
    result = direction_check
    return result if result.present?

    # reject inbound call
    result = reject_check
    if result.present? && result[:action] == 'reject'
      @params['comment'] = 'reject, busy'
      if @params['user'].present?
        @params['comment'] = "#{@params['user']} -> reject, busy"
      end
      Cti::Log.process(@params)
      return result
    end

    # set caller id of outbound call
    result = caller_id_rewrite(@params)
    if result.present? && result[:action] == 'set_caller_id'
      @params['from'] = result[:params][:from_caller_id]
      Cti::Log.process(@params)
      return result
    end

    log = Cti::Log.process(@params)

    # push new call notification
    push_incoming_call(log)

    # open screen if call got answered
    push_open_ticket_screen(log)

    result || {}
  end

  def direction_check

    # check possible directions
    if @params['direction'] != 'in' && @params['direction'] != 'out'
      return {
        action: 'invalid_direction',
        params: @params
      }
    end

    nil
  end

  def reject_check
    return nil if @params['direction'] != 'in'
    return nil if @params['event'] != 'newCall'

    config_inbound = @config[:inbound] || {}
    block_caller_ids = config_inbound[:block_caller_ids] || []

    # check if call need to be blocked
    block_caller_ids.each do |item|
      next if item[:caller_id] != @params['from']

      return {
        action: 'reject'
      }
    end
    nil
  end

  def caller_id_rewrite(params)
    return nil if params['direction'] != 'out'
    return nil if params['event'] != 'newCall'

    config_outbound = @config[:outbound]
    routing_table = nil
    default_caller_id = nil
    if config_outbound.present?
      routing_table = config_outbound[:routing_table]
      default_caller_id = config_outbound[:default_caller_id]
    end

    to = params[:to]
    return nil if to.blank?

    if routing_table.present?
      routing_table.each do |row|
        dest = row[:dest].gsub(%r{\*}, '.+?')
        next if !to.match?(%r{^#{dest}$})

        return {
          action: 'set_caller_id',
          params: {
            from_caller_id: row[:caller_id],
            to_caller_id:   params[:to],
          }
        }
      end
    end

    if default_caller_id.present?
      return {
        action: 'set_caller_id',
        params: {
          from_caller_id: default_caller_id,
          to_caller_id:   params[:to],
        }
      }
    end

    nil
  end

  def push_open_ticket_screen(log)
    return if log.destroyed?
    return if @params[:event] != 'answer'
    return if @params[:direction] != 'in'

    user = push_open_ticket_screen_recipient
    return if !user
    return if !user.permissions?('cti.agent')

    customer_id = log.best_customer_id_of_log_entry

    # open user profile if user has a ticket in the last 30 days
    if customer_id
      last_activity = Setting.get('cti_customer_last_activity')
      if Ticket.where(customer_id: customer_id).exists?(['updated_at > ?', last_activity.seconds.ago])
        PushMessages.send_to(user.id, {
                               event: 'remote_task',
                               data:  {
                                 key:        "User-#{customer_id}",
                                 controller: 'UserProfile',
                                 params:     { user_id: customer_id.to_s },
                                 show:       true,
                                 url:        "user/profile/#{customer_id}"
                               },
                             })
        return
      end
    end

    id = rand(999_999_999)
    PushMessages.send_to(user.id, {
                           event: 'remote_task',
                           data:  {
                             key:        "TicketCreateScreen-#{id}",
                             controller: 'TicketCreate',
                             params:     { customer_id: customer_id.to_s, title: 'Call', id: id },
                             show:       true,
                             url:        "ticket/create/id/#{id}"
                           },
                         })
  end

  def push_open_ticket_screen_recipient

    # try to find answering which answered call
    user = nil

    # based on answeringNumber
    if @params[:answeringNumber].present?
      user = Cti::CallerId.known_agents_by_number(@params[:answeringNumber]).first
      if !user
        user = User.find_by(phone: @params[:answeringNumber], active: true)
      end
    end

    # based on user param
    if !user && @params[:user].present?
      user = User.find_by(login: @params[:user].downcase)
    end

    # based on user_id param
    if !user && @params[:user_id].present?
      user = User.find_by(id: @params[:user_id])
    end

    user
  end

  def push_incoming_call(log)
    return if log.destroyed?
    return if @params[:event] != 'newCall'
    return if @params[:direction] != 'in'

    # check if only a certain user should get the notification
    if @config[:notify_map].present?
      user_ids = []
      @config[:notify_map].each do |row|
        next if row[:user_ids].blank? || row[:queue] != @params[:to]

        row[:user_ids].each do |user_id|
          user = User.find_by(id: user_id)
          next if !user
          next if !user.permissions?('cti.agent')

          user_ids.push user.id
        end
      end

      # add agents which have this number directly assigned
      Cti::CallerId.known_agents_by_number(@params[:to]).each do |user|
        next if !user
        next if !user.permissions?('cti.agent')

        user_ids.push user.id
      end

      user_ids.uniq.each do |user_id|
        PushMessages.send_to(
          user_id,
          {
            event: 'cti_event',
            data:  log,
          },
        )
      end
      return true
    end

    # send notify about event
    users = User.with_permissions('cti.agent')
    users.each do |user|
      PushMessages.send_to(
        user.id,
        {
          event: 'cti_event',
          data:  log,
        },
      )
    end
    true
  end

end
