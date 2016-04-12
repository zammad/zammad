# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::Icinga

  # according
  # https://github.com/Icinga/icinga2/blob/master/etc/icinga2/scripts/mail-service-notification.sh
  # http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/monitoring-basics#host-states
  # http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/monitoring-basics#service-states

  def self.run(_channel, mail)
    return if !Setting.get('ichinga_integration')

    # set config
    integration = 'ichinga'
    sender = Setting.get('ichinga_sender')
    auto_close = Setting.get('ichinga_auto_close')
    auto_close_state_id = Setting.get('ichinga_auto_close_state_id')
    state_recovery_match = 'OK'

    return if !mail[:from]
    return if !mail[:body]
    sender_user_id = mail[ 'x-zammad-customer-id'.to_sym ]
    return if !sender_user_id

    # check if sender is ichinga
    return if !mail[:from].match(/#{sender}/i)

    # get mail attibutes like host and state
    result = {}
    mail[:body].gsub(%r{(Service|Host|State|Address|Date/Time|Additional\sInfo):(.+?)\n}i) { |_match|
      key = $1
      if key
        key = key.downcase
      end
      value = $2
      if value
        value.strip!
      end
      result[key] = value
    }

    # check if ticket with host is open
    customer = User.lookup(id: sender_user_id)

    # follow up detection by meta data
    open_states = Ticket::State.by_category('open')
    Ticket.where(state: open_states).each {|ticket|
      next if !ticket.preferences
      next if !ticket.preferences['integration']
      next if ticket.preferences['integration'] != integration
      next if !ticket.preferences['ichinga']
      next if !ticket.preferences['ichinga']['host']
      next if ticket.preferences['ichinga']['host'] != result['host']
      next if ticket.preferences['ichinga']['service'] != result['service']

      # found open ticket for service+host
      mail[ 'x-zammad-ticket-id'.to_sym ] = ticket.id

      # check if service is recovered
      if auto_close && result['state'].match(/#{state_recovery_match}/i)
        state = Ticket::State.lookup(id: auto_close_state_id)
        if state
          mail[ 'x-zammad-ticket-followup-state'.to_sym ] = state.name
        end
      end
      return true
    }

    # new ticket, set meta data
    if !mail[ 'x-zammad-ticket-id'.to_sym ]
      if !mail[ 'x-zammad-ticket-preferences'.to_sym ]
        mail[ 'x-zammad-ticket-preferences'.to_sym ] = {}
      end
      preferences = {}
      preferences['integration'] = integration
      preferences['ichinga'] = result
      preferences.each {|key, value|
        mail[ 'x-zammad-ticket-preferences'.to_sym ][key] = value
      }
    end
  end
end
