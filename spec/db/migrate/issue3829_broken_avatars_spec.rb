# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3829BrokenAvatars, type: :db_migration do
  let(:user)   { create(:agent) }
  let(:avatar) { create(:avatar, o_id: user.id, source_url: source_url) }

  context 'when avatar is stored correctly' do
    let(:source_url) { 'https://zammad.org/avatar.png' }

    before do
      user.update(image_source: avatar.source_url)
    end

    it 'is not removed' do
      expect { migrate }.not_to change { Avatar.exists?(id: avatar.id) }
    end
  end

  context 'when avatar is stored without file ending' do
    let(:source_url) { 'https://zammad.org/avatar' }

    before do
      user.update(image_source: avatar.source_url)
    end

    it 'is removed' do
      expect { migrate }.to change { Avatar.exists?(id: avatar.id) }.to(false)
    end
  end
end
