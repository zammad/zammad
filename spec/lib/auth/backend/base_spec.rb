# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/auth/backend/backend_examples'

RSpec.describe Auth::Backend::Base do

  let(:user)     { create(:user) }
  let(:auth)     { Auth.new(user.login, 'not_used') }
  let(:instance) { described_class.new({ adapter: described_class.name }, auth) }

  describe '#valid?' do
    it_behaves_like 'Auth backend'
  end
end
