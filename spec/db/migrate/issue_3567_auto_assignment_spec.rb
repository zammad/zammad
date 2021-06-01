# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3567AutoAssignment, type: :db_migration, db_strategy: :reset do
  context 'when setting contains article keys' do
    before do
      Setting.set('ticket_auto_assignment_selector', { 'condition'=>{ 'article.subject'=>{ 'operator' => 'contains', 'value' => 'test' } } })
      migrate
    end

    it 'config gets removed' do
      config = Setting.get('ticket_auto_assignment_selector')
      expect(config['condition']['article.subject']).to be nil
    end
  end
end
