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
    return if !Channel::Filter::Match::EmailRegex.match(value: mail[:from], match_rule: sender, check_mode: true)

    # get mail attributes like host and state
    result = {}

    mail[:body].gsub(%r{(Service|Host|State|Address|Date/Time|Additional\sInfo|Info|Action|Description):(.+?)(\n|$)}i) do |_match|
      key = $1
      if key
        key = key.downcase
      end
      value = $2
      value&.strip!
      result[key] = value
    end

    # check min. params
    return if result['host'].blank?

    # icinga - get state by body - new templates
    if result['state'].blank?
      if mail[:body] =~ /.+?\sis\s(.+?)\!/
        result['state'] = $1
      end
    end

    # icinga - get state by subject - new templates "state:" is not in body anymore
    # Subject: [PROBLEM] Ping IPv4 on host1234.dc.example.com is WARNING!
    # Subject: [PROBLEM] Host host1234.dc.example.com is DOWN!
    if result['state'].blank?
      if mail[:subject] =~ /(on|Host)\s.+?\sis\s(.+?)\!/
        result['state'] = $2
      end
    end

    # monit - get missing attributes from body
    if result['service'].blank?
      if mail[:body] =~ /\sService\s(.+?)\s/
        result['service'] = $1
      end
    end

    # possible event types https://mmonit.com/monit/documentation/#Setting-an-event-filter
    if result['state'].blank?
      result['state'] = if mail[:body].match?(/\s(done|recovery|succeeded|bytes\sok|packets\sok)\s/)
                          'OK'
                        elsif mail[:body].match?(/(instance\schanged\snot|Link\sup|Exists|Saturation\sok|Speed\sok)/)
                          'OK'
                        else
                          'CRITICAL'
                        end
    end

    # follow-up detection by meta data
    open_states = Ticket::State.by_category(:open)
    ticket_ids = Ticket.where(state: open_states).order(created_at: :desc).limit(5000).pluck(:id)
    ticket_ids.each do |ticket_id|
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
    end

    # new ticket, set meta data
    if !mail[ 'x-zammad-ticket-id'.to_sym ]
      if !mail[ 'x-zammad-ticket-preferences'.to_sym ]
        mail[ 'x-zammad-ticket-preferences'.to_sym ] = {}
      end
      preferences = {}
      preferences[integration] = result
      preferences.each do |key, value|
        mail[ 'x-zammad-ticket-preferences'.to_sym ][key] = value
      end
    end

    # ignore states
    if state_ignore_match.present? && result['state'].present? && result['state'].match(/#{state_ignore_match}/i)
      mail[ 'x-zammad-ignore'.to_sym ] = true
      return true
    end

    # if now problem exists, just ignore the email
    if result['state'].present? && result['state'].match(/#{state_recovery_match}/i)
      mail[ 'x-zammad-ignore'.to_sym ] = true
      return true
    end

    true
  end
end
