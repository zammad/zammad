# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Article::HighlightedTextUpsert < BaseMutation
    description 'Store highlighted text in the article preferences'

    argument :article_id, GraphQL::Types::ID, loads: Gql::Types::Ticket::ArticleType, loads_pundit_method: :update?, description: 'The article to be updated'
    argument :highlight, [Gql::Types::Input::Ticket::Article::HighlightedTextInputType], required: false, description: 'Structured input for highlighted text information (start index, end index, color class)'

    field :success, Boolean, null: false, description: 'Did the highlight data get successfully stored?'

    requires_permission 'ticket.agent'

    def resolve(article:, highlight: nil)
      article.preferences ||= {}
      article.preferences['highlight'] = transform(article:, highlight:)
      article.save!

      { success: true }
    end

    private

    def transform(article:, highlight:)
      return if highlight.nil?

      highlight.each_with_index.map do |highlight_info, index|
        "#{highlight_info[:start_index]}$#{highlight_info[:end_index]}$#{index + 1}$#{highlight_info[:color_class]}$article-content-#{article.id}"
      end.join('|').then { |highlights_str| "type:TextRange|#{highlights_str}" }
    end
  end
end
