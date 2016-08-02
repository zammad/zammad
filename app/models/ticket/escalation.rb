# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
module Ticket::Escalation

=begin

rebuild escalations for all open tickets

  result = Ticket::Escalation.rebuild_all

returns

  result = true

=end

  def self.rebuild_all
    state_list_open = Ticket::State.by_category('open')

    tickets = Ticket.where(state_id: state_list_open)
    tickets.each(&:escalation_calculation)
  end

=begin

rebuild escalation for ticket

  ticket = Ticket.find(123)
  result = ticket.escalation_calculation

returns

  result = true

=end

  def escalation_calculation

    # set escalation off if ticket is already closed
    state = Ticket::State.lookup(id: state_id)
    escalation_disabled = false
    if state.ignore_escalation?
      escalation_disabled = true
    end

    # get sla for ticket
    calendar = nil
    sla = escalation_calculation_get_sla
    if sla
      calendar = sla.calendar
    end

    # if no escalation is enabled
    if !sla || !calendar

      # nothing to change
      return true if !escalation_time

      self.escalation_time = nil
      self.updated_by_id   = 1
      self.callback_loop   = true
      save
      return true
    end

    # reset escalation attributes
    self.escalation_time           = nil
    self.first_response_escal_date = nil
    self.update_time_escal_date    = nil
    self.close_time_escal_date     = nil

    biz = Biz::Schedule.new do |config|

      # get business hours
      hours = {}
      calendar.business_hours.each { |day, meta|
        next if !meta[:active]
        next if !meta[:timeframes]
        hours[day.to_sym] = {}
        meta[:timeframes].each { |frame|
          next if !frame[0]
          next if !frame[1]
          hours[day.to_sym][frame[0]] = frame[1]
        }
      }
      config.hours = hours
      if !hours || hours.empty?
        raise "No congifure hours found in calendar #{calendar.inspect}"
      end

      # get holidays
      holidays = []
      if calendar.public_holidays
        calendar.public_holidays.each { |day, meta|
          next if !meta
          next if !meta['active']
          next if meta['removed']
          holidays.push Date.parse(day)
        }
      end
      config.holidays = holidays

      # get timezone
      config.time_zone = calendar.timezone
    end

    # fist response
    # calculate first response escalation
    if sla.first_response_time
      self.first_response_escal_date = destination_time(created_at, sla.first_response_time, biz)
    end

    # get response time in min
    if first_response
      self.first_response_in_min = pending_minutes(created_at, first_response, biz, 'business_minutes')
    else
      self.escalation_time = first_response_escal_date
    end

    # set time to show if sla is raised or not
    if sla.first_response_time && first_response_in_min
      self.first_response_diff_in_min = sla.first_response_time - first_response_in_min
    end

    # update time
    # calculate escalation
    if !last_contact_customer && !last_contact_agent
      last_update = created_at
    elsif !last_contact_customer && last_contact_agent
      last_update = last_contact_agent
    elsif last_contact_customer && !last_contact_agent
      last_update = last_contact_customer
    elsif last_contact_agent > last_contact_customer
      last_update = last_contact_agent
    elsif last_contact_agent < last_contact_customer
      last_update = last_contact_customer
    end
    if sla.update_time && last_update
      self.update_time_escal_date = destination_time(last_update, sla.update_time, biz)
    end
    if update_time_escal_date && ((!escalation_time && update_time_escal_date) || update_time_escal_date < escalation_time)
      self.escalation_time = update_time_escal_date
    end

    # get update time in min
    if last_update && last_update != created_at
      self.update_time_in_min = pending_minutes(created_at, last_update, biz, 'business_minutes')
    end

    # set sla time
    if sla.update_time && update_time_in_min
      self.update_time_diff_in_min = sla.update_time - update_time_in_min
    end

    # close time
    # calculate close time escalation
    if sla.solution_time
      self.close_time_escal_date = destination_time(created_at, sla.solution_time, biz)
    end

    # get close time in min
    if close_time
      self.close_time_in_min = pending_minutes(created_at, close_time, biz, 'business_minutes')
    elsif close_time_escal_date && ((!escalation_time && close_time_escal_date) || close_time_escal_date < escalation_time)
      self.escalation_time = close_time_escal_date
    end

    # set time to show if sla is raised or not
    if sla.solution_time && close_time_in_min
      self.close_time_diff_in_min = sla.solution_time - close_time_in_min
    end

    if escalation_disabled
      self.escalation_time = nil
    end

    return if !changed?

    self.callback_loop = true
    self.updated_by_id = 1
    save
  end

=begin

return sla for ticket

  ticket = Ticket.find(123)
  result = ticket.escalation_calculation_get_sla

returns

  result = selected_sla

=end

  def escalation_calculation_get_sla
    sla_selected = nil
    sla_list = Cache.get('SLA::List::Active')
    if sla_list.nil?
      sla_list = Sla.all.order(:name, :created_at)
      Cache.write('SLA::List::Active', sla_list, { expires_in: 1.hour })
    end
    sla_list.each { |sla|
      if !sla.condition || sla.condition.empty?
        sla_selected = sla
      elsif sla.condition
        query_condition, bind_condition = Ticket.selector2sql(sla.condition)
        ticket = Ticket.where(query_condition, *bind_condition).find_by(id: id)
        next if !ticket
        sla_selected = sla
        break
      end
    }
    sla_selected
  end

  private

=begin

return destination_time for time range

  destination_time = destination_time(start_time, move_minutes, biz)

returns

  destination_time = Time.zone.parse('2016-08-02T11:11:11Z')

=end

  def destination_time(start_time, move_minutes, biz)
    destination_time = biz.time(move_minutes, :minutes).after(start_time)

    # go step by step to end of pending_minutes until pending_minutes is 0
    pending_start_time = start_time
    500.times.each {

      # check if we have pending time in the range to the destination time
      pending_minutes = pending_minutes(pending_start_time, destination_time, biz)

      # skip if no pending time is given
      break if !pending_minutes || pending_minutes <= 0

      # set pending destination to start time and add pending time to destination time
      pending_start_time = destination_time
      destination_time   = biz.time(pending_minutes, :minutes).after(destination_time)
    }

    destination_time
  end

  # get business minutes of pending time
  #  type = business_minutes (pending time in business minutes)
  #  type = non_business_minutes (pending time in non business minutes)
  def pending_minutes(start_time, end_time, biz, type = 'non_business_minutes')

    working_time_in_min      = 0
    total_time_in_min        = 0
    last_state               = nil
    last_state_change        = nil
    last_state_is_pending    = false
    pending_minutes          = 0
    ignore_escalation_states = Ticket::State.where(
      ignore_escalation: true,
    ).map(&:name)

    history_get.each { |history_item|

      # ignore if it isn't a state change
      next if !history_item['attribute']
      next if history_item['attribute'] != 'state'

      # ignore all newer state before start_time
      next if history_item['created_at'] < start_time

      # ignore all older state changes after end_time
      next if last_state_change && last_state_change > end_time

      # if created_at is later then end_time, use end_time as last time
      if history_item['created_at'] > end_time
        history_item['created_at'] = end_time
      end

      # get initial state and time
      if !last_state
        last_state        = history_item['value_from']
        last_state_change = start_time
      end

      # check if time need to be counted
      counted = true
      if ignore_escalation_states.include?(history_item['value_from'])
        counted = false
      end

      diff = biz.within(last_state_change, history_item['created_at']).in_minutes
      if counted
        # puts "Diff count #{history_item['value_from']} -> #{history_item['value_to']} / #{last_state_change} -> #{history_item['created_at']}"
        working_time_in_min = working_time_in_min + diff
        # else
        # puts "Diff not count #{history_item['value_from']} -> #{history_item['value_to']} / #{last_state_change} -> #{history_item['created_at']}"
      end
      total_time_in_min = total_time_in_min + diff

      last_state_is_pending = false
      if ignore_escalation_states.include?(history_item['value_to'])
        last_state_is_pending = true
      end

      # remember for next loop last state
      last_state        = history_item['value_to']
      last_state_change = history_item['created_at']
    }

    # if last state isnt pending, count rest
    if !last_state_is_pending && last_state_change && last_state_change < end_time
      diff = biz.within(last_state_change, end_time).in_minutes
      working_time_in_min = working_time_in_min + diff
      total_time_in_min = total_time_in_min + diff
    end

    # if we have not had any state change
    if !last_state_change
      diff = biz.within(start_time, end_time).in_minutes
      working_time_in_min = working_time_in_min + diff
      total_time_in_min = total_time_in_min + diff
    end

    #puts "#{type}:working_time_in_min:#{working_time_in_min}|free_time:#{total_time_in_min - working_time_in_min}"
    if type == 'non_business_minutes'
      return total_time_in_min - working_time_in_min
    end
    working_time_in_min
  end

end
