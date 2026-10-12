# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Tasks::Zammad::Command do
  context 'when listing all commands' do
    it 'rake finds zammad commands' do
      expect(Rake::Task.task_defined?('zammad:package:reinstall_all')).to be(true)
    end
  end
end
