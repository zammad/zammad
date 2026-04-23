# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::SharedDraft::Start::Create < Service::Base
  requires_current_user!

  attr_reader :name, :group, :content, :form_id

  def initialize(form_id, name:, group:, content:)
    @form_id = form_id
    @name    = name
    @group   = group
    @content = content
  end

  def execute
    shared_draft = ::Ticket::SharedDraftStart.new(name:, group:, content:)

    Pundit.authorize(current_user, shared_draft, :create?)

    shared_draft.save!
    shared_draft.attach_upload_cache form_id

    shared_draft
  end
end
