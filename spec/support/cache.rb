# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|
  # Cache setup must be the first before hook
  # Otherwise authenticated_as hook fails with random errors
  config.prepend_before(:each) do
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
