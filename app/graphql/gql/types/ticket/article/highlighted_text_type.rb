# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::Article
  class HighlightedTextType < Gql::Types::BaseObject
    description 'Ticket article highlighted text information'

    field :start_index, Integer, null: false
    field :end_index, Integer, null: false
    field :color_class, String, null: false

    def start_index
      @object.split('$')[0].to_i
    end

    def end_index
      @object.split('$')[1].to_i
    end

    def color_class
      @object.split('$')[3].downcase
    end
  end
end
