# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|
  config.around(:each, :application_handle) do |example|
    ApplicationHandleInfo.use(example.metadata[:application_handle]) do
      example.run
    end
  end
end
