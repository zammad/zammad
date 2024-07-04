# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::SharedDraft::Start::Create < Service::Base
  attr_reader :user, :name, :group, :content, :form_id

  def initialize(user, form_id, name:, group:, content:)
    super()

    @user    = user
    @form_id = form_id
    @name    = name
    @group   = group
    @content = content
  end

  def execute
    shared_draft = ::Ticket::SharedDraftStart.new(name:, group:, content:)

    Pundit.authorize(user, shared_draft, :create?)

    UserInfo.with_user_id(user.id) do
      shared_draft.save!
      shared_draft.attach_upload_cache form_id
    end

    shared_draft
  end
end
