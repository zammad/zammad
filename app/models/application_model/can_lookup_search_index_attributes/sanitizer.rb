# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ApplicationModel::CanLookupSearchIndexAttributes::Sanitizer
  extend ActiveSupport::Concern

=begin

This function sanitizes store attributes for the search index.

  job = Job.find(123)
  sanitized_attributes = job.search_index_sanitize_store_attributes(attributes)

returns

  sanitized_attributes # sanitized attributes

=end

  def search_index_sanitize_store_attributes(attributes)
    store_columns = SearchIndexBackend::STORE_NAMES_PER_MODEL[self.class]
    return attributes if store_columns.blank?

    store_columns.each do |column|
      next if attributes[column].blank?

      attributes[column] = search_index_sanitize_store_value(attributes[column])
    end

    attributes
  end

=begin

This function sanitizes store values for the search index.

  job               = Job.find(123)
  sanitized_perform = job.search_index_sanitize_store_value(value.perform)

returns

  sanitized_perform # sanitized value

=end

  def search_index_sanitize_store_value(data, key: nil, max_length: 1_000)
    case data
    when Hash
      data.each do |key, value|
        data[key] = search_index_sanitize_store_value(value, key:, max_length:)
      end
    when Array
      data.map! do |value|
        search_index_sanitize_store_value(value, max_length:)
      end
    when String
      if key == 'body'
        data = data.html2text
      end

      data = data[0..max_length]
    end

    data
  end
end
