# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Create < Service::Base
  include Service::Concerns::HandlesCoreWorkflow

  requires_current_user!

  attr_reader :ticket_data

  def initialize(ticket_data:)
    @ticket_data = ticket_data
  end

  def execute
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
        log_snipeit_asset_links(ticket)
      end
    end
  end

  private

  def create_article(ticket, article_data)
    return if article_data.blank?

    preprocess_article_data! ticket, article_data

    Service::Ticket::Article::Create
      .with_current_user(current_user)
      .execute(article_data: article_data, ticket: ticket)
  end

  # Assets selected while creating a ticket are stored as part of the ticket itself, not as
  # a later change, so Service::Ticket::ExternalReferences::Snipeit::LinkAssets never sees a
  # diff to derive the history from. Without this, unlinking such an asset would leave a
  # 'removed' entry with no matching 'added' one.
  #
  # Reads the ids off the saved ticket rather than the input, so it covers both the
  # externalReferences input used by the Vue create screen and the raw preferences the
  # legacy sidebar appends to the create request.
  def log_snipeit_asset_links(ticket)
    return if !Setting.get('snipeit_integration')

    asset_ids = Array(ticket.preferences.dig(:snipeit, :asset_ids)).map(&:to_i).uniq
    return if asset_ids.blank?

    asset_ids.each do |asset_id|
      ticket.history_log('added', current_user.id, { history_attribute: 'snipeit', value_to: Snipeit.asset_label(asset_id) })
    end
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

    Pundit.authorize current_user, ticket, :agent_create_access?

    link_data.each do |link|
      case link[:link_object]
      when ::Ticket
        Pundit.authorize current_user, link[:link_object], :agent_read_access?
      when ::KnowledgeBase::Answer::Translation
        Pundit.authorize current_user, link[:link_object], :show?
      end

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
      next if !external_reference_enabled?(external_references, key)

      add_external_reference_preference(ticket_data, key, { issue_links: external_references[key].map(&:to_s) })
    end

    if external_reference_enabled?(external_references, :idoit)
      add_external_reference_preference(ticket_data, :idoit, { object_ids: external_references[:idoit] })
    end

    return if !external_reference_enabled?(external_references, :snipeit)

    add_external_reference_preference(ticket_data, :snipeit, { asset_ids: external_references[:snipeit] })
  end

  def external_reference_enabled?(external_references, key)
    external_references[key].present? && Setting.get("#{key}_integration")
  end

  def add_external_reference_preference(ticket_data, key, value)
    ticket_data[:preferences] ||= {}
    ticket_data[:preferences][key] = value
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
      raise Exceptions::UnprocessableContent, __('Shared draft cannot be selected for this ticket.')
    end

    shared_draft.destroy!
  end
end
