# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
# rubocop:disable ClassAndModuleChildren
module Ticket::Escalation

=begin

rebuild escalations for all open tickets

  result = Ticket::Escalation.rebuild_all

returns

  result = true

=end

  def self.rebuild_all
    state_list_open = Ticket::State.by_category( 'open' )

    tickets = Ticket.where( state_id: state_list_open )
    tickets.each {|ticket|
      ticket.escalation_calculation
    }
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
    state = Ticket::State.lookup( id: self.state_id )
    if state.ignore_escalation?

      # nothing to change
      return true if !self.escalation_time

      self.escalation_time            = nil
      #      self.first_response_escal_date  = nil
      #      self.close_time_escal_date      = nil
      self.callback_loop = true
      self.save
      return true
    end

    # get sla for ticket
    sla_selected = escalation_calculation_get_sla

    # reset escalation if no sla is set
    if !sla_selected

      # nothing to change
      return true if !self.escalation_time

      self.escalation_time            = nil
      #      self.first_response_escal_date  = nil
      #      self.close_time_escal_date      = nil
      self.callback_loop = true
      self.save
      return true
    end

    #    puts sla_selected.inspect
    #    puts days.inspect
    self.escalation_time            = nil
    self.first_response_escal_date  = nil
    self.update_time_escal_date     = nil
    self.close_time_escal_date      = nil

    # first response
    if sla_selected.first_response_time

      # get escalation date without pending time
      self.first_response_escal_date = TimeCalculation.dest_time( self.created_at, sla_selected.first_response_time, sla_selected.data, sla_selected.timezone )

      # get pending time between created and first response escal. time
      time_in_pending = escalation_suspend( self.created_at, self.first_response_escal_date, 'relative', sla_selected, sla_selected.first_response_time )

      # get new escalation time (original escal_date + time_in_pending)
      self.first_response_escal_date = TimeCalculation.dest_time( self.first_response_escal_date, time_in_pending.to_i, sla_selected.data, sla_selected.timezone )

      # set ticket escalation
      self.escalation_time = calculation_higher_time( self.escalation_time, self.first_response_escal_date, self.first_response )
    end
    if self.first_response# && !self.first_response_in_min

      # get response time in min between created and first response
      self.first_response_in_min = escalation_suspend( self.created_at, self.first_response, 'real', sla_selected )

    end

    # set time to show if sla is raised ot in
    if sla_selected.first_response_time && self.first_response_in_min
      self.first_response_diff_in_min = sla_selected.first_response_time - self.first_response_in_min
    end

    # update time
    last_update = self.last_contact_agent
    if !last_update
      last_update = self.created_at
    end
    if sla_selected.update_time
      self.update_time_escal_date = TimeCalculation.dest_time( last_update, sla_selected.update_time, sla_selected.data, sla_selected.timezone  )

      # get pending time between created and update escal. time
      time_in_pending = escalation_suspend( last_update, self.update_time_escal_date, 'relative', sla_selected, sla_selected.update_time )

      # get new escalation time (original escal_date + time_in_pending)
      self.update_time_escal_date = TimeCalculation.dest_time( self.update_time_escal_date, time_in_pending.to_i, sla_selected.data, sla_selected.timezone )

      # set ticket escalation
      self.escalation_time = calculation_higher_time( self.escalation_time, self.update_time_escal_date, false )
    end
    if self.last_contact_agent
      self.update_time_in_min = TimeCalculation.business_time_diff( self.created_at, self.last_contact_agent, sla_selected.data, sla_selected.timezone  )
    end

    # set sla time
    if sla_selected.update_time && self.update_time_in_min
      self.update_time_diff_in_min = sla_selected.update_time - self.update_time_in_min
    end

    # close time
    if sla_selected.close_time

      # get escalation date without pending time
      self.close_time_escal_date = TimeCalculation.dest_time( self.created_at, sla_selected.close_time, sla_selected.data, sla_selected.timezone  )

      # get pending time between created and close escal. time
      extended_escalation = escalation_suspend( self.created_at, self.close_time_escal_date, 'relative', sla_selected, sla_selected.close_time )

      # get new escalation time (original escal_date + time_in_pending)
      self.close_time_escal_date = TimeCalculation.dest_time( self.close_time_escal_date, extended_escalation.to_i, sla_selected.data, sla_selected.timezone )

      # set ticket escalation
      self.escalation_time = calculation_higher_time( self.escalation_time, self.close_time_escal_date, self.close_time )
    end
    if self.close_time # && !self.close_time_in_min
      self.close_time_in_min = escalation_suspend( self.created_at, self.close_time, 'real', sla_selected )
    end
    # set sla time
    if sla_selected.close_time && self.close_time_in_min
      self.close_time_diff_in_min = sla_selected.close_time - self.close_time_in_min
    end

    return if !self.changed?

    self.callback_loop = true
    self.save
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
    sla_list = Cache.get( 'SLA::List::Active' )
    if sla_list.nil?
      sla_list = Sla.where( active: true )
      Cache.write( 'SLA::List::Active', sla_list, { expires_in: 1.hour } )
    end
    sla_list.each {|sla|
      if !sla.condition || sla.condition.empty?
        sla_selected = sla
      elsif sla.condition
        hit = false
        map = [
          [ 'tickets.priority_id', 'priority_id' ],
          [ 'tickets.group_id', 'group_id' ]
        ]
        map.each {|item|

          next if !sla.condition[ item[0] ]

          if sla.condition[ item[0] ].class == String
            sla.condition[ item[0] ] = [ sla.condition[ item[0] ] ]
          end
          if sla.condition[ item[0] ].include?( self[ item[1] ].to_s )
            hit = true
          else
            hit = false
          end
        }
        if hit
          sla_selected = sla
        end
      end
    }
    sla_selected
  end

  private

  #type could be:
  # real - time without supsend state
  # relative - only suspend time

  def escalation_suspend (start_time, end_time, type, sla_selected, sla_time = 0)
    if type == 'relative'
      end_time += sla_time * 60
    end
    total_time_without_pending = 0
    total_time = 0
    #get history for ticket
    history_list = self.history_get

    #loop through hist. changes and get time
    last_state            = nil
    last_state_change     = nil
    last_state_is_pending = false
    history_list.each { |history_item|

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
      if history_item['value_from'] == 'pending reminder'
        counted = false
      elsif history_item['value_from'] == 'close'
        counted = false
      end

      diff = escalation_time_diff( last_state_change, history_item['created_at'], sla_selected )
      if counted
        # puts "Diff count #{history_item['value_from']} -> #{history_item['value_to']} / #{last_state_change} -> #{history_item['created_at']}"
        total_time_without_pending = total_time_without_pending + diff
      # else
      # puts "Diff not count #{history_item['value_from']} -> #{history_item['value_to']} / #{last_state_change} -> #{history_item['created_at']}"
      end
      total_time = total_time + diff

      if history_item['value_to'] == 'pending reminder'
        last_state_is_pending = true
      else
        last_state_is_pending = false
      end

      # remember for next loop last state
      last_state        = history_item['value_to']
      last_state_change = history_item['created_at']
    }

    # if last state isnt pending, count rest
    if !last_state_is_pending && last_state_change && last_state_change < end_time
      diff = escalation_time_diff( last_state_change, end_time, sla_selected )
      # puts "Diff count last state was not pending #{diff.to_s} - #{last_state_change} - #{end_time}"
      total_time_without_pending = total_time_without_pending + diff
      total_time = total_time + diff
    end

    # if we have not had any state change
    if !last_state_change
      diff = escalation_time_diff( start_time, end_time, sla_selected )
      # puts 'Diff state has not changed ' + diff.to_s
      total_time_without_pending = total_time_without_pending + diff
      total_time = total_time + diff
    end

    #return sum
    if type == 'real'
      return total_time_without_pending
    elsif type == 'relative'
      relative = total_time - total_time_without_pending
      return relative
    else
      raise "ERROR: Unknown type #{type}"
    end
  end

  def escalation_time_diff( start_time, end_time, sla_selected )
    if sla_selected
      diff = TimeCalculation.business_time_diff( start_time, end_time, sla_selected.data, sla_selected.timezone)
    else
      diff = TimeCalculation.business_time_diff( start_time, end_time )
    end
    diff
  end

  def calculation_higher_time(escalation_time, check_time, done_time)
    return escalation_time if done_time
    return check_time if !escalation_time
    return escalation_time if !check_time
    return check_time if escalation_time > check_time
    escalation_time
  end
end
