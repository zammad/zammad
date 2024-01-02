# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::ExternalDataSource::Preview < Service::Base
  def execute(data_option:, render_context:, term:, limit: 10)
    result = ExternalDataSource.new(options: data_option, render_context:, term:, limit:).process

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
