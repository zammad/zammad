# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Job::SearchIndex
  extend ActiveSupport::Concern

  def search_index_attribute_lookup(include_references: true)
    attributes = super
    attributes.delete('timeplan')
    attributes
  end
end
