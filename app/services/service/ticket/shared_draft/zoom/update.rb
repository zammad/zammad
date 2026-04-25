# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::SharedDraft::Zoom::Update < Service::Base
  requires_current_user!

  attr_reader :form_id, :shared_draft, :new_article, :ticket_attributes

  def initialize(form_id, shared_draft, new_article:, ticket_attributes:)
    @form_id           = form_id
    @shared_draft      = shared_draft
    @new_article       = new_article
    @ticket_attributes = ticket_attributes
  end

  def execute
    shared_draft.new_article       = new_article
    shared_draft.ticket_attributes = ticket_attributes

    Pundit.authorize(current_user, shared_draft, :update?)

    shared_draft.save!
    shared_draft.attach_upload_cache(form_id)

    shared_draft
  end
end
