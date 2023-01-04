# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Create < Service::BaseWithCurrentUser
  include Service::Concerns::HandlesCoreWorkflow

  def execute(ticket_data:)
    Transaction.execute do
      set_core_workflow_information(ticket_data, ::Ticket, 'create_middle')

      article_data = ticket_data.delete(:article)
      tag_data     = ticket_data.delete(:tags)

      Ticket.new(ticket_data).tap do |ticket|
        Pundit.authorize current_user, ticket, :create?
        ticket.save!

        create_article(ticket, article_data)
        assign_tags(ticket, tag_data)
      end
    end
  end

  private

  def create_article(ticket, article_data)
    return if article_data.blank?

    Service::Ticket::Article::Create.new(current_user: current_user).execute(article_data: article_data.to_h.merge!(ticket_id: ticket.id))
  end

  def assign_tags(ticket, tag_data)
    return if tag_data.blank?

    tag_data.each { |tag| ticket.tag_add(tag.strip) }
  end
end
