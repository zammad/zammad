# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Channel::Filter::MonitoringBase

  # according

  # Icinga
  # https://github.com/Icinga/icinga2/blob/master/etc/icinga2/scripts/mail-service-notification.sh
  # http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/monitoring-basics#host-states
  # http://docs.icinga.org/icinga2/latest/doc/module/icinga2/chapter/monitoring-basics#service-states

  # Nagios
  # https://github.com/NagiosEnterprises/nagioscore/blob/754218e67653929a58938b99ef6b6039b6474fe4/sample-config/template-object/commands.cfg.in#L35

  def self.run(_channel, mail)
    integration = integration_name
    return if !Setting.get("#{integration}_integration")
    sender = Setting.get("#{integration}_sender")
    auto_close = Setting.get("#{integration}_auto_close")
    auto_close_state_id = Setting.get("#{integration}_auto_close_state_id")
    state_ignore_match = Setting.get("#{integration}_ignore_match") || ''
    state_recovery_match = Setting.get("#{integration}_recovery_match") || '(OK|UP)'

    return if mail[:from].blank?
    return if mail[:body].blank?
    session_user_id = mail[ 'x-zammad-session-user-id'.to_sym ]
    return if !session_user_id

    # check if sender is monitoring
    return if !Channel::Filter::Database.match(mail[:from], sender, true, true)

    # get mail attibutes like host and state
    result = {}
    mail[:body].gsub(%r{(Service|Host|State|Address|Date/Time|Additional\sInfo|Info):(.+?)\n}i) { |_match|
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

    # check min. params
    return if result['host'].blank?

    # get state from body
    if result['state'].blank?
      if mail[:body] =~ /==>.*\sis\s(.+?)\!\s+?<==/
        result['state'] = $1
      end
    end

    # get state from subject
    if result['state'].blank?
      if mail[:subject] =~ /on\s.+?\sis\s(.+?)\!/
        result['state'] = $1
      end
    end

    # check if ticket with host is open
    customer = User.lookup(id: session_user_id)

    # follow up detection by meta data
    open_states = Ticket::State.by_category(:open)
    ticket_ids = Ticket.where(state: open_states).order(created_at: :desc).limit(5000).pluck(:id)
    ticket_ids.each { |ticket_id|
      ticket = Ticket.find_by(id: ticket_id)
      next if !ticket
      next if !ticket.preferences
      next if !ticket.preferences[integration]
      next if !ticket.preferences[integration]['host']
      next if ticket.preferences[integration]['host'] != result['host']
      next if ticket.preferences[integration]['service'] != result['service']

      # found open ticket for service+host
      mail[ 'x-zammad-ticket-id'.to_sym ] = ticket.id

      # check if service is recovered
      if auto_close && result['state'].present? && result['state'].match(/#{state_recovery_match}/i)
        Rails.logger.info "MonitoringBase.#{integration} set autoclose to state_id #{auto_close_state_id}"
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
      preferences[integration] = result
      preferences.each { |key, value|
        mail[ 'x-zammad-ticket-preferences'.to_sym ][key] = value
      }
    end

    # ignorte states
    if state_ignore_match.present? && result['state'].present? && result['state'].match(/#{state_ignore_match}/i)
      mail[ 'x-zammad-ignore'.to_sym ] = true
      return true
    end

    # if now problem exists, just ignore the email
    if result['state'].present? && result['state'].match(/#{state_recovery_match}/i)
      mail[ 'x-zammad-ignore'.to_sym ] = true
      return true
    end

  end
end
