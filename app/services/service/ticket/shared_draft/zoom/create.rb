# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::SharedDraft::Zoom::Create < Service::Base
  attr_reader :user, :form_id, :ticket, :new_article, :ticket_attributes

  def initialize(user, form_id, ticket:, new_article:, ticket_attributes:)
    super()

    @user              = user
    @form_id           = form_id
    @ticket            = ticket
    @new_article       = new_article
    @ticket_attributes = ticket_attributes
  end

  def execute
    shared_draft = ::Ticket::SharedDraftZoom.new(ticket:, new_article:, ticket_attributes:)

    Pundit.authorize(user, shared_draft, :update?)

    UserInfo.with_user_id(user.id) do
      shared_draft.save!
      shared_draft.attach_upload_cache(form_id)
    end

    shared_draft
  end
end
