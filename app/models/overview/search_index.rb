# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Overview::SearchIndex
  extend ActiveSupport::Concern

  def search_index_attribute_lookup(include_references: true)
    attributes = super
    attributes.delete('view')
    attributes.delete('order')
    attributes
  end
end
