RSpec.configure do |config|
  config.around(:each, :application_handle) do |example|
    ApplicationHandleInfo.use(example.metadata[:application_handle]) do
      example.run
    end
  end
end
