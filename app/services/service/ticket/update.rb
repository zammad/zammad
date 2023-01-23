# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Update < Service::BaseWithCurrentUser
  include Service::Concerns::HandlesCoreWorkflow

  def execute(ticket:, ticket_data:)

    Pundit.authorize current_user, ticket, :update?
    set_core_workflow_information(ticket_data, ::Ticket, 'edit')
    article_data = ticket_data.delete(:article)

    ticket.with_lock do
      ticket.update!(ticket_data)

      create_article(ticket, article_data) if article_data.present?
    end

    ticket
  end

  private

  def create_article(ticket, article_data)
    return if article_data.blank?

    Service::Ticket::Article::Create.new(current_user: current_user).execute(article_data: article_data.to_h.merge!(ticket_id: ticket.id))
  end
end
