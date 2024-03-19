# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Translation::Search::Collector::ObjectManagerAttributes < Service::Translation::Search::Collector
  private

  def list_sources
    @list_sources ||= display_names | option_labels
  end

  def search_sources
    @search_sources ||= list_sources.select { |source| source.downcase.include?(query.downcase) }
  end

  def object_attributes
    @object_attributes ||= ObjectManager::Attribute.where(editable: true)
  end

  def display_names
    object_attributes.pluck(:display)
  end

  def option_labels
    labels = []

    object_attributes.each do |attribute|
      labels |= labels_from_options(attribute)
    end

    labels
  end

  def labels_from_options(attribute)
    options = attribute[:data_option][:options]

    return [] if !attribute[:data_option][:translate] || options.nil?

    if options.is_a?(Array)
      return collect_labels(attribute[:data_option][:options])
    end

    options.values
  end

  def collect_labels(options, labels = [])
    options.each do |option|
      # Collect the 'name' value if it exists
      labels << option['name'] if option['name']

      # If 'children' key exists and is an array, recursively collect labels from the children
      if option['children'].is_a?(Array)
        collect_labels(option['children'], labels)
      end
    end
    labels
  end
end
