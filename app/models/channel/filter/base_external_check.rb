# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Channel::Filter::BaseExternalCheck

  # required mail header to start the detection
  MAIL_HEADER        = 'x-example-header'.freeze

  # regex to detect the id in the subject of the email
  SOURCE_ID_REGEX    = %r{\s(EXAMPLE-MATCH\d+)\s}

  # External sync references source name prefix
  SOURCE_NAME_PREFIX = 'Example'.freeze

  # This filter will run pre and post
  def self.run(_channel, mail, ticket_or_transaction_params = nil, _article = nil, _session_user = nil)
    return if mail[const_get(:MAIL_HEADER)].blank?

    source_id = self.source_id(subject: mail[:subject])
    return if source_id.blank?

    source_name = self.source_name(from: mail[:from])
    return if source_name.blank?

    # check if we can followup by existing service now relation
    if ticket_or_transaction_params.blank? || ticket_or_transaction_params.is_a?(Hash)
      from_sync_entry(
        mail:        mail,
        source_name: source_name,
        source_id:   source_id,
      )
      return
    end

    ExternalSync.create_with(source_id: source_id).find_or_create_by(source: source_name, object: 'Ticket', o_id: ticket_or_transaction_params.id)
  end

=begin

This function returns the source id of the service now email if given.

  source_id = Channel::Filter::ServiceNowCheck.source_id(
    from:    'test@service-now.com',
    subject: 'Incident INC12345 --- test',
  )

returns:

  source_id = 'INC12345'

=end

  def self.source_id(subject: '')

    # check if we can find the service now relation
    source_id = nil
    if subject =~ const_get(:SOURCE_ID_REGEX)
      source_id = $1
    end

    source_id
  end

=begin

This function returns the sync id of the service now email if given.

  source_name = Channel::Filter::ServiceNowCheck.source_name(
    from:    'test@service-now.com',
  )

returns:

  source_name = 'ServiceNow-test@service-now.com'

=end

  def self.source_name(from:)
    address = Mail::AddressList.new(from).addresses.first.address.downcase
    "#{const_get(:SOURCE_NAME_PREFIX)}-#{address}"
  rescue => e
    Rails.logger.info "Unable to parse email address in '#{from}': #{e.message}"
  end

  def self.from_sync_entry(mail:, source_name:, source_id:)
    sync_entry = ExternalSync.find_by(
      source:    source_name,
      source_id: source_id,
      object:    'Ticket',
    )
    return if sync_entry.blank?

    mail[ :'x-zammad-ticket-id' ] = sync_entry.o_id
  end
end
