# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ExcelSheet::Ticket < ExcelSheet

=begin

  excel = ExcelSheet::Ticket.new(
    title:                        "#{year}-#{month}",
    ticket_ids:                   ticket_ids,
    additional_attributes:        additional_attributes,
    additional_attributes_header: additional_attributes_header,
    timezone:                     params[:timezone],
    locale:                       current_user.locale,
  )

  excel.content

=end

  def initialize(params)
    @ticket_ids                   = params[:ticket_ids] || []
    @additional_attributes        = params[:additional_attributes] || []
    @additional_attributes_header = params[:additional_attributes_header] || []

    super(
      title:    params[:title],
      header:   ticket_header,
      records:  [],
      timezone: params[:timezone],
      locale:   params[:locale]
    )
  end

  def ticket_header
    header = [
      { display: '#', name: 'number', width: 18, data_type: 'string' },
      { display: __('Title'), name: 'title', width: 34, data_type: 'string' },
      { display: __('State'), name: 'state_id', width: 14, data_type: 'string' },
      { display: __('Priority'), name: 'priority_id', width: 14, data_type: 'string' },
      { display: __('Group'), name: 'group_id', width: 20, data_type: 'string' },
      { display: __('Owner'), name: 'owner_id', width: 20, data_type: 'string' },
      { display: __('Customer'), name: 'customer_id', width: 20, data_type: 'string' },
      { display: __('Organization'), name: 'organization_id', width: 20, data_type: 'string' },
      { display: __('Create Channel'), name: 'create_article_type_id', width: 10, data_type: 'string' },
      { display: __('Sender'), name: 'create_article_sender_id', width: 14, data_type: 'string' },
      { display: __('Tags'), name: 'tag_list', width: 20, data_type: 'string' },
      { display: __('Time Units Total'), name: 'time_unit', width: 10, data_type: 'float' },
    ]

    header.concat(@additional_attributes_header) if @additional_attributes_header

    # ObjectManager attributes
    ObjectManager::Attribute
      .where(
        active:        true,
        to_create:     false,
        object_lookup: ObjectLookup.lookup(name: 'Ticket')
      )
      .where.not(
        name:    header.pluck(:name)
      )
      .where.not(
        display: header.pluck(:display)
      )
      .pluck_as_hash(:name, :display, :data_type, :data_option)
      .each { |elem| elem[:width] = 20 }
      .then { |objects| header.concat(objects) }

    header.push(
      { display: __('Created At'), name: 'created_at', width: 18, data_type: 'datetime' },
      { display: __('Updated At'), name: 'updated_at', width: 18, data_type: 'datetime' },
      { display: __('Closed At'), name: 'close_at', width: 18, data_type: 'datetime' },
      { display: __('Close Escalation At'), name: 'close_escalation_at', width: 18, data_type: 'datetime' },
      { display: __('Close In Min'), name: 'close_in_min', width: 10, data_type: 'integer' },
      { display: __('Close Diff In Min'), name: 'close_diff_in_min', width: 10, data_type: 'integer' },
      { display: __('First Response At'), name: 'first_response_at', width: 18, data_type: 'datetime' },
      { display: __('First Response Escalation At'), name: 'first_response_escalation_at', width: 18, data_type: 'datetime' },
      { display: __('First Response In Min'), name: 'first_response_in_min', width: 10, data_type: 'integer' },
      { display: __('First Response Diff In Min'), name: 'first_response_diff_in_min', width: 10, data_type: 'integer' },
      { display: __('Update Escalation At'), name: 'update_escalation_at', width: 18, data_type: 'datetime' },
      { display: __('Update In Min'), name: 'update_in_min', width: 10, data_type: 'integer' },
      { display: __('Update Diff In Min'), name: 'update_diff_in_min', width: 10, data_type: 'integer' },
      { display: __('Last Contact At'), name: 'last_contact_at', width: 18, data_type: 'datetime' },
      { display: __('Last Contact Agent At'), name: 'last_contact_agent_at', width: 18, data_type: 'datetime' },
      { display: __('Last Contact Customer At'), name: 'last_contact_customer_at', width: 18, data_type: 'datetime' },
      { display: __('Article Count'), name: 'article_count', width: 10, data_type: 'integer' },
      { display: __('Escalation At'), name: 'escalation_at', width: 18, data_type: 'datetime' },
    )

  end

  def gen_rows
    @ticket_ids.each_with_index do |ticket_id, index|
      ticket = ::Ticket.lookup(id: ticket_id)
      raise "Can't find Ticket with ID #{ticket_id} for '#{@title}' #{self.class.name} generation" if !ticket

      gen_row_by_header(ticket, @additional_attributes[index])
    rescue => e
      Rails.logger.error e
    end
  end

end
