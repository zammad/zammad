# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.around(:each, :application_handle) do |example|
    ApplicationHandleInfo.use(example.metadata[:application_handle]) do
      example.run
    end
  end

  config.around(:each, :application_handle_context) do |example|
    ApplicationHandleInfo.in_context(example.metadata[:application_handle_context]) do
      example.run
    end
  end
end
