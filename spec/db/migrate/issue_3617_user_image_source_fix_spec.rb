# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3617UserImageSourceFix, type: :db_migration, db_strategy: :reset do
  describe 'when invalid user' do
    let!(:user) do
      user = create(:user)
      user.update_column(:image_source, 'invalid stuff!!!')
      user
    end

    it 'removes invalid image sources' do
      migrate
      expect(user.reload.image_source).to eq(nil)
    end
  end

  describe 'when valid user' do
    let!(:user) do
      user = create(:user)
      user.update_column(:image_source, 'https://zammad.org/avatar.png')
      user
    end

    it 'does not change anything' do
      migrate
      expect(user.reload.image_source).to eq('https://zammad.org/avatar.png')
    end
  end
end
