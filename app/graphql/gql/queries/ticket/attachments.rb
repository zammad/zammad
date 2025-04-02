# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::Attachments < BaseQuery

    description 'Fetch ticket attachments by ticket ID'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, description: 'The ticket to fetch attachments for'

    type [Gql::Types::StoredFileType, { null: false }], null: false

    def resolve(ticket:)
      articles = Service::Ticket::Article::List
        .new(current_user: context.current_user)
        .execute(ticket:)

      return [] if articles.blank?

      inline_attachments = articles.map { |x| x.attachments_inline.map(&:id) }.flatten.uniq

      articles
        .map(&:attachments)
        .flatten
        .reject { |f| inline_attachment?(inline_attachments, f) || original_format?(f) }
        .uniq(&:store_file_id)
        .sort_by(&:created_at).reverse
    end

    private

    def inline_attachment?(inline_attachments, file)
      inline_attachments.include?(file.id)
    end

    def original_format?(file)
      return false if file.preferences.blank?
      return false if !file.preferences.key?('original-format')
      return false if file.preferences['original-format'].blank?

      file.preferences['original-format']
    end
  end
end
