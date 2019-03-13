RSpec.configure do |config|

  config.around(:each, :application_handle) do |example|
    ApplicationHandleInfo.current = example.metadata[:application_handle]
    begin
      example.run
    ensure
      ApplicationHandleInfo.current = nil
    end
  end
end
