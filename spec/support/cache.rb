RSpec.configure do |config|
  config.before(:each) do
    # clear the cache otherwise it won't
    # be able to recognize the rollbacks
    # done by RSpec
    Cache.clear
  end
end
