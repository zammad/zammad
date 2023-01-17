# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4461KbFeedTokenPersistent, current_user_id: 1, type: :db_migration do
  context 'when a KB feed token exists' do
    before do
      Token.ensure_token! 'KnowledgeBaseFeed'
    end

    it 'makes token persistent' do
      expect { migrate }
        .to change { Token.find_by(action: 'KnowledgeBaseFeed').persistent }
        .to(true)
    end
  end

  context 'when a different token exists' do
    before do
      Token.ensure_token! 'OtherToken'
    end

    it 'does not touch the token' do
      expect { migrate }
        .not_to change { Token.find_by(action: 'OtherToken').persistent }
    end
  end
end
