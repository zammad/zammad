# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::ServiceNowCheck

  # This filter will run pre and post
  def self.run(_channel, mail, ticket = nil, _article = nil, _session_user = nil)
    source_id = self.source_id(from: mail[:from], subject: mail[:subject])
    return if source_id.blank?

    # check if we can followup by existing service now relation
    if ticket.blank?
      sync_entry = ExternalSync.find_by(
        source:    'ServiceNow',
        source_id: source_id,
        object:    'Ticket',
      )
      return if sync_entry.blank?

      mail[ 'x-zammad-ticket-id'.to_sym ] = sync_entry.o_id
      return
    end

    ExternalSync.create_with(source_id: source_id).find_or_create_by(source: 'ServiceNow', object: 'Ticket', o_id: ticket.id)
  end

=begin

This function returns the source id of the service now email if given.

  source_id = Channel::Filter::ServiceNowCheck.source_id(
    from:    'test@servicnow.com',
    subject: 'Incident INC12345 --- test',
  )

returns:

  source_id = 'INC12345'

=end

  def self.source_id(from: '', subject: '')

    # check if data is sent by service now
    begin
      return if Mail::AddressList.new(from).addresses.none? do |line|
        line.address.end_with?('@service-now.com')
      end
    rescue
      Rails.logger.info "Unable to parse email address in '#{from}'"
    end

    # check if we can find the service now relation
    source_id = nil
    if subject =~ /\s(INC\d+)\s/
      source_id = $1
    end

    source_id
  end
end
