# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Create < Service::BaseWithCurrentUser
  include Service::Concerns::HandlesCoreWorkflow

  def execute(ticket_data:)
    Transaction.execute do
      handle_shared_draft(ticket_data)

      set_core_workflow_information(ticket_data, ::Ticket, 'create_middle')

      article_data = ticket_data.delete(:article)
      tag_data     = ticket_data.delete(:tags)
      link_data    = ticket_data.delete(:links)

      find_or_create_customer(ticket_data)
      preprocess_ticket_data! ticket_data

      Ticket.new(ticket_data).tap do |ticket|
        Pundit.authorize current_user, ticket, :create?
        ticket.save!

        create_article(ticket, article_data)
        assign_tags(ticket, tag_data)
        add_links(ticket, link_data)
      end
    end
  end

  private

  def create_article(ticket, article_data)
    return if article_data.blank?

    preprocess_article_data! ticket, article_data

    Service::Ticket::Article::Create
      .new(current_user: current_user)
      .execute(article_data: article_data, ticket: ticket)
  end

  def assign_tags(ticket, tag_data)
    return if tag_data.blank?

    tag_data.each do |tag|
      next if !::Tag.tag_allowed?(name: tag.strip, user_id: current_user.id)

      ticket.tag_add(tag.strip)
    end
  end

  def add_links(ticket, link_data)
    return if link_data.blank?

    link_data.each do |link|
      Link.add(
        link_type:                link[:link_type],
        link_object_target:       link[:link_object].class.name,
        link_object_target_value: link[:link_object].id,
        link_object_source:       'Ticket',
        link_object_source_value: ticket.id,
      )
    end
  end

  def find_or_create_customer(ticket_data)
    return if ticket_data[:customer].blank? || ticket_data[:customer].is_a?(::User)

    email_address = ticket_data[:customer]
    EmailAddressValidation.new(email_address).valid!

    customer = User.find_by(email: email_address.downcase)
    if customer.present?
      ticket_data[:customer] = customer
      return
    end

    customer = User.create(
      firstname: '',
      lastname:  '',
      email:     email_address,
      password:  '',
      active:    true,
    )
    ticket_data[:customer] = customer
  end

  # Desktop UI supplies this data from frontend
  # Mobile UI leaves this processing for GraphQL
  def preprocess_ticket_data!(ticket_data)
    if customer?(ticket_data[:group]&.id)
      ticket_data[:customer_id] = current_user.id
      ticket_data.delete(:external_references)
    end

    move_issue_trackers_links_to_preferences(ticket_data)
  end

  # Desktop UI supplies this data from frontend
  # Mobile UI leaves this processing for GraphQL
  def preprocess_article_data!(ticket, article_input)
    if customer? ticket.group_id
      preprocess_permission_customer! ticket, article_input
      return
    end

    case article_input[:sender]
    when 'Customer'
      preprocess_article_data_customer! ticket, article_input
    when 'Agent'
      preprocess_article_data_agent! ticket, article_input
    end
  end

  def move_issue_trackers_links_to_preferences(ticket_data)
    external_references = ticket_data.delete(:external_references)

    return if external_references.blank?

    %i[github gitlab].each do |key|
      input = external_references[key]

      next if input.blank? || !Setting.get("#{key}_integration")

      ticket_data[:preferences] ||= {}
      ticket_data[:preferences][key] = { issue_links: input.map(&:to_s) }
    end

    # idoit
    idoit_object_ids = external_references[:idoit]

    return if idoit_object_ids.blank? || !Setting.get('idoit_integration')

    ticket_data[:preferences] ||= {}
    ticket_data[:preferences][:idoit] = { object_ids: idoit_object_ids }
  end

  def customer?(group_id)
    return if !current_user.permissions?('ticket.customer')

    !current_user.group_access?(group_id, :create)
  end

  def preprocess_permission_customer!(ticket, article_input)
    article_input.merge!(
      from: current_user.fullname,
      to:   group_name(ticket)
    )
  end

  def preprocess_article_data_customer!(ticket, article_input)
    article_input.merge!(
      from: customer_recipient_line(ticket),
      to:   group_name(ticket)
    )
  end

  def preprocess_article_data_agent!(ticket, article_input)
    article_input.merge!(
      from: group_name(ticket),
      to:   customer_recipient_line(ticket)
    )
  end

  def group_name(ticket)
    ticket.group&.name || ''
  end

  def customer_recipient_line(ticket)
    customer = ticket.customer

    return if !customer

    Channel::EmailBuild.recipient_line "#{customer.firstname} #{customer.lastname}".presence, customer.email
  end

  def handle_shared_draft(ticket_data)
    shared_draft = ticket_data.delete(:shared_draft)

    return if !shared_draft

    if shared_draft.group_id != ticket_data[:group].id || !shared_draft.group.shared_drafts?
      raise Exceptions::UnprocessableEntity, __('Shared draft cannot be selected for this ticket.')
    end

    shared_draft.destroy!
  end
end
