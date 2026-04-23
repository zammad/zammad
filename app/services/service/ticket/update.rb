# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Update < Service::Base
  include Service::Concerns::HandlesCoreWorkflow

  requires_current_user!

  attr_reader :ticket, :ticket_data, :skip_validators, :macro

  def initialize(ticket:, ticket_data:, skip_validators: nil, macro: nil)
    @ticket = ticket
    @ticket_data = ticket_data
    @skip_validators = skip_validators
    @macro = macro
  end

  def execute
    set_core_workflow_information(ticket_data, ::Ticket, 'edit')

    article_data = ticket_data.delete(:article)

    validate!(current_user, ticket, ticket_data, article_data, skip_validators, macro)

    save_ticket!(ticket, ticket_data, article_data, macro)

    ticket.reload
  end

  private

  def save_ticket!(ticket, ticket_data, article_data, macro)
    ticket.with_lock do

      handle_shared_draft(ticket, ticket_data)

      if macro
        save_ticket_attributes_and_apply_macro!(ticket, ticket_data, article_data, macro)
      else
        save_ticket_attributes!(ticket, ticket_data, article_data)
      end
    end
  end

  def save_ticket_attributes!(ticket, ticket_data, article_data)
    ticket.update!(ticket_data)
    create_article(ticket, article_data)
  end

  def save_ticket_attributes_and_apply_macro!(ticket, ticket_data, article_data, macro)
    ticket.assign_attributes(ticket_data)
    ticket.perform_changes(macro, 'macro', nil, current_user.id) do |object, _save_needed|
      object.save!
      create_article(ticket, article_data)
    end
  end

  def create_article(ticket, article_data)
    return if article_data.blank?

    preprocess_article_data! article_data

    Service::Ticket::Article::Create
      .with_current_user(current_user)
      .execute(article_data: article_data, ticket: ticket)
  end

  # Desktop UI supplies this data from frontend
  # Mobile UI leaves this processing for GraphQL
  def preprocess_article_data!(article_input)
    article_input[:from] = current_user.fullname
  end

  def validate!(user, ticket, ticket_data, article_data, skip_validators, macro) # rubocop:disable Metrics/ParameterLists
    Service::Ticket::Update::Validator
      .with_current_user(user)
      .execute(ticket:, ticket_data:, article_data:, skip_validators:, macro:)
  end

  def handle_shared_draft(ticket, ticket_data)
    shared_draft = ticket_data.delete(:shared_draft)

    return if !shared_draft

    if shared_draft && shared_draft.ticket != ticket
      raise Exceptions::UnprocessableContent, __('Shared draft cannot be selected for this ticket.')
    end

    shared_draft.destroy!
  end
end
