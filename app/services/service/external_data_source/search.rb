# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::ExternalDataSource::Search < Service::Base
  attr_reader :attribute, :render_context, :term, :limit

  def initialize(attribute:, render_context:, term:, limit: 10)
    @attribute = attribute
    @render_context = render_context
    @term = term
    @limit = limit
  end

  def execute
    ExternalDataSource.new(options: attribute.data_option, render_context: render_context, term: term, limit: limit).process
  rescue ExternalDataSource::Errors::BaseError => e
    raise Exceptions::UnprocessableContent, e.log_message(attribute_display)
  end

  def attribute_display
    "#{attribute.object_lookup.name}.#{attribute.name}"
  end
end
