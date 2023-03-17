# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExternalCredential::Exchange do
  describe "Exchange Oauth token update job is always marked as failed job when it's not configured #4454", performs_jobs: true do
    it 'does always return a value' do
      expect(described_class.refresh_token).to be_truthy
    end
  end
end
