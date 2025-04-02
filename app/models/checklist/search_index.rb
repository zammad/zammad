# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Checklist
  module SearchIndex
    extend ActiveSupport::Concern

    def search_index_attribute_lookup(include_references: true)
      attributes = super

      attributes['items'] = items.map do |item|
        item.search_index_attribute_lookup(include_references: include_references)
      end

      attributes
    end
  end
end
