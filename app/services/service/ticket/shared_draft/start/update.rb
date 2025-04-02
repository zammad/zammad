# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::SharedDraft::Start::Update < Service::Base
  attr_reader :user, :name, :group, :content, :form_id, :shared_draft

  def initialize(user, shared_draft, form_id, group:, content:, name: nil)
    super()

    @user         = user
    @shared_draft = shared_draft
    @form_id      = form_id
    @name         = name
    @group        = group
    @content      = content
  end

  def execute
    shared_draft.group   = group
    shared_draft.content = content

    # name can be changed via REST api, but GraphQL mutation does not support it
    shared_draft.name = name if !name.nil?

    Pundit.authorize(user, shared_draft, :update?)

    UserInfo.with_user_id(user.id) do
      shared_draft.save!
      shared_draft.attach_upload_cache form_id
    end

    shared_draft
  end
end
