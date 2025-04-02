# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::ExternalDataSource::Search < Service::Base
  def execute(attribute:, render_context:, term:, limit: 10)
    @attribute = attribute

    ExternalDataSource.new(options: attribute.data_option, render_context:, term:, limit:).process
  rescue ExternalDataSource::Errors::BaseError => e
    raise Exceptions::UnprocessableEntity, e.log_message(attribute_display)
  end

  def attribute_display
    "#{@attribute.object_lookup.name}.#{@attribute.name}"
  end
end
