# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::ExternalDataSource::Preview < Service::Base
  attr_reader :data_option, :render_context, :term, :limit

  def initialize(data_option:, render_context:, term:, limit: 10)
    @data_option = data_option
    @render_context = render_context
    @term = term
    @limit = limit
  end

  def execute
    result = ExternalDataSource.new(options: data_option, render_context: render_context, term: term, limit: limit).process

    {
      success: true,
      data:    result
    }
  rescue ExternalDataSource::Errors::BaseError => e
    {
      success:       false,
      error:         e.message,
      response_body: e.external_data_source.json,
      parsed_items:  e.external_data_source.parsed_items,
    }
  end
end
