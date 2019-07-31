# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module Ticket::Escalation

=begin

rebuild escalations for all open tickets

  result = Ticket::Escalation.rebuild_all

returns

  result = true

=end

  def self.rebuild_all
    state_list_open = Ticket::State.by_category(:open)

    ticket_ids = Ticket.where(state_id: state_list_open).limit(20_000).pluck(:id)
    ticket_ids.each do |ticket_id|
      next if !Ticket.exists?(ticket_id)

      Ticket.find(ticket_id).escalation_calculation(true)
    end
  end

=begin

rebuild escalation for ticket

  ticket = Ticket.find(123)
  result = ticket.escalation_calculation

returns

  result = true # true = ticket has been updated | false = no changes on ticket

=end

  def escalation_calculation(force = false)
    return if !escalation_calculation_int(force)

    self.callback_loop = true
    save!
    self.callback_loop = false
    true
  end

  def escalation_calculation_int(force = false)
    return if callback_loop == true

    # return if we run import mode
    return if Setting.get('import_mode') && !Setting.get('import_ignore_sla')

    # set escalation off if current state is not escalation relative (e.g. ticket is closed)
    return if !state_id

    state = Ticket::State.lookup(id: state_id)
    escalation_disabled = false
    if state.ignore_escalation?
      escalation_disabled = true

      # early exit if nothing current state is not escalation relative
      if !force
        return false if escalation_at.nil?

        self.escalation_at = nil
        if preferences['escalation_calculation']
          preferences['escalation_calculation']['escalation_disabled'] = escalation_disabled
        end
        return true
      end
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
      return false if !escalation_at && !first_response_escalation_at && !update_escalation_at && !close_escalation_at

      preferences['escalation_calculation'] = {}
      self.escalation_at = nil
      self.first_response_escalation_at = nil
      self.escalation_at = nil
      self.update_escalation_at = nil
      self.close_escalation_at = nil
      if preferences['escalation_calculation']
        preferences['escalation_calculation']['escalation_disabled'] = escalation_disabled
      end
      return true
    end

    # get last_update_at
    if !last_contact_customer_at && !last_contact_agent_at
      last_update_at = created_at
    elsif !last_contact_customer_at && last_contact_agent_at
      last_update_at = last_contact_agent_at
    elsif last_contact_customer_at && !last_contact_agent_at
      last_update_at = last_contact_customer_at
    elsif last_contact_agent_at > last_contact_customer_at
      last_update_at = last_contact_agent_at
    elsif last_contact_agent_at < last_contact_customer_at
      last_update_at = last_contact_customer_at
    end

    # check if calculation need be done
    escalation_calculation = preferences[:escalation_calculation] || {}
    sla_changed = true
    if escalation_calculation['sla_id'] == sla.id && escalation_calculation['sla_updated_at'] == sla.updated_at
      sla_changed = false
    end
    calendar_changed = true
    if escalation_calculation['calendar_id'] == calendar.id && escalation_calculation['calendar_updated_at'] == calendar.updated_at
      calendar_changed = false
    end
    if sla_changed == true || calendar_changed == true
      force = true
    end
    first_response_at_changed = true
    if escalation_calculation['first_response_at'] == first_response_at
      first_response_at_changed = false
    end
    last_update_at_changed = true
    if escalation_calculation['last_update_at'] == last_update_at && !saved_change_to_attribute('state_id')
      last_update_at_changed = false
    end
    close_at_changed = true
    if escalation_calculation['close_at'] == close_at
      close_at_changed = false
    end

    if !force && preferences[:escalation_calculation]
      if first_response_at_changed == false &&
         last_update_at_changed == false &&
         close_at_changed == false &&
         sla_changed == false &&
         calendar_changed == false &&
         escalation_calculation['escalation_disabled'] == escalation_disabled
        return false
      end
    end

    # reset escalation attributes
    self.escalation_at = nil
    if force == true
      self.first_response_escalation_at = nil
      self.update_escalation_at    = nil
      self.close_escalation_at     = nil
    end
    biz = Biz::Schedule.new do |config|

      # get business hours
      hours = calendar.business_hours_to_hash
      raise "No configured hours found in calendar #{calendar.inspect}" if hours.blank?

      config.hours = hours

      # get holidays
      config.holidays = calendar.public_holidays_to_array
      config.time_zone = calendar.timezone
    end

    # get history data
    history_data = nil

    # calculate first response escalation
    if force == true || first_response_at_changed == true
      if !history_data
        history_data = history_get
      end
      if sla.first_response_time
        self.first_response_escalation_at = destination_time(created_at, sla.first_response_time, biz, history_data)
      end

      # get response time in min
      if first_response_at
        self.first_response_in_min = period_working_minutes(created_at, first_response_at, biz, history_data)
      end

      # set time to show if sla is raised or not
      if sla.first_response_time && first_response_in_min
        self.first_response_diff_in_min = sla.first_response_time - first_response_in_min
      end
    end

    # calculate update time escalation
    if force == true || last_update_at_changed == true
      if !history_data
        history_data = history_get
      end
      if sla.update_time && last_update_at
        self.update_escalation_at = destination_time(last_update_at, sla.update_time, biz, history_data)
      end

      # get update time in min
      if last_update_at && last_update_at != created_at
        self.update_in_min = period_working_minutes(created_at, last_update_at, biz, history_data)
      end

      # set sla time
      if sla.update_time && update_in_min
        self.update_diff_in_min = sla.update_time - update_in_min
      end
    end

    # calculate close time escalation
    if force == true || close_at_changed == true
      if !history_data
        history_data = history_get
      end
      if sla.solution_time
        self.close_escalation_at = destination_time(created_at, sla.solution_time, biz, history_data)
      end

      # get close time in min
      if close_at
        self.close_in_min = period_working_minutes(created_at, close_at, biz, history_data)
      end

      # set time to show if sla is raised or not
      if sla.solution_time && close_in_min
        self.close_diff_in_min = sla.solution_time - close_in_min
      end
    end

    # set closest escalation time
    if escalation_disabled
      self.escalation_at = nil
    else
      if !first_response_at && first_response_escalation_at
        self.escalation_at = first_response_escalation_at
      end
      if update_escalation_at && ((!escalation_at && update_escalation_at) || update_escalation_at < escalation_at)
        self.escalation_at = update_escalation_at
      end
      if !close_at && close_escalation_at && ((!escalation_at && close_escalation_at) || close_escalation_at < escalation_at)
        self.escalation_at = close_escalation_at
      end
    end

    # remember already counted time to do on next update only the diff
    preferences[:escalation_calculation] = {
      first_response_at:   first_response_at,
      last_update_at:      last_update_at,
      close_at:            close_at,
      sla_id:              sla.id,
      sla_updated_at:      sla.updated_at,
      calendar_id:         calendar.id,
      calendar_updated_at: calendar.updated_at,
      escalation_disabled: escalation_disabled,
    }
    true
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
    sla_list.each do |sla|
      if sla.condition.blank?
        sla_selected = sla
      elsif sla.condition
        query_condition, bind_condition, tables = Ticket.selector2sql(sla.condition)
        ticket = Ticket.where(query_condition, *bind_condition).joins(tables).find_by(id: id)
        next if !ticket

        sla_selected = sla
        break
      end
    end
    sla_selected
  end

  private

=begin

return destination_time for time range

  destination_time = destination_time(start_time, move_minutes, biz, history_data)

returns

  destination_time = Time.zone.parse('2016-08-02T11:11:11Z')

=end

  def destination_time(start_time, move_minutes, biz, history_data)
    local_destination_time = biz.time(move_minutes, :minutes).after(start_time)

    # go step by step to end of move_minutes until move_minutes is 0
    200.times.each do |_count|

      # check if we have pending time in the range to the destination time
      working_minutes = period_working_minutes(start_time, local_destination_time, biz, history_data, true)
      move_minutes -= working_minutes

      # skip if no pending time is given
      break if move_minutes <= 0

      # set pending destination to start time and add pending time to destination time
      start_time             = local_destination_time
      local_destination_time = biz.time(move_minutes, :minutes).after(start_time)
    end
    local_destination_time
  end

  # get period working minutes time in minutes
  def period_working_minutes(start_time, end_time, biz, history_list, add_current = false)

    working_time_in_min      = 0
    last_state               = nil
    last_state_change        = nil
    ignore_escalation_states = Ticket::State.where(
      ignore_escalation: true,
    ).map(&:name)

    # add state changes till now
    if add_current && saved_change_to_attribute('state_id') && saved_change_to_attribute('state_id')[0] && saved_change_to_attribute('state_id')[1]
      last_history_state = nil
      history_list.each do |history_item|
        next if !history_item['attribute']
        next if history_item['attribute'] != 'state'
        next if history_item['id']

        last_history_state = history_item
      end
      local_updated_at = updated_at
      if saved_change_to_attribute('updated_at') && saved_change_to_attribute('updated_at')[1]
        local_updated_at = saved_change_to_attribute('updated_at')[1]
      end
      history_item = {
        'attribute'  => 'state',
        'created_at' => local_updated_at,
        'value_from' => Ticket::State.find(saved_change_to_attribute('state_id')[0]).name,
        'value_to'   => Ticket::State.find(saved_change_to_attribute('state_id')[1]).name,
      }
      if last_history_state
        last_history_state = history_item
      else
        history_list.push history_item
      end
    end

    history_list.each do |history|

      # ignore if it isn't a state change
      next if !history['attribute']
      next if history['attribute'] != 'state'

      created_at = history['created_at']

      # ignore all newer state before start_time
      next if created_at < start_time

      # ignore all older state changes after end_time
      next if last_state_change && last_state_change > end_time

      # if created_at is later then end_time, use end_time as last time
      if created_at > end_time
        created_at = end_time
      end

      # get initial state and time
      if !last_state
        last_state        = history['value_from']
        last_state_change = start_time
      end

      # check if time need to be counted
      counted = true
      if ignore_escalation_states.include?(history['value_from'])
        counted = false
      end

      if counted
        diff = biz.within(last_state_change, created_at).in_minutes
        working_time_in_min += diff
      end

      # remember for next loop last state
      last_state        = history['value_to']
      last_state_change = created_at
    end

    # if we have time to count after history entries has finished
    if last_state_change && last_state_change < end_time
      diff = biz.within(last_state_change, end_time).in_minutes
      working_time_in_min += diff
    end

    # if we have not had any state change
    if !last_state_change
      diff = biz.within(start_time, end_time).in_minutes
      working_time_in_min += diff
    end

    working_time_in_min
  end

end
