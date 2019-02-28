RSpec.configure do |config|
  config.before(:each) do
    # clear the cache otherwise it won't
    # be able to recognize the rollbacks
    # done by RSpec
    Cache.clear

    # clear Setting cache to prevent leaking
    # of Setting changes from previous test examples
    Setting.reload

    # reset bulk import to prevent wrong base setting
    BulkImportInfo.disable
  end
end
