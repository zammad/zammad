# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Tasks::Zammad::Command do
  context 'when listing all commands' do
    it 'rake finds zammad commands' do
      expect(`bundle exec rake --tasks`).to include('zammad:package:reinstall_all')
    end
  end
end
