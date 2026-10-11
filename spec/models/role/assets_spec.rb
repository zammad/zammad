# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Role::Assets, type: :model do
  let(:role) { create(:role, note: 'hello') }

  def attributes_for_user(user)
    UserInfo.with_user_id(user.id) { role.attributes_with_association_ids }
  end

  describe '#filter_unauthorized_attributes' do
    it 'masks the name and hides the details from a customer' do
      expect(attributes_for_user(create(:customer)))
        .to include('id' => role.id, 'name' => "Role_#{role.id}")
        .and not_include('note', 'default_at_signup', 'preferences')
    end

    it 'exposes all attributes to an agent' do
      expect(attributes_for_user(create(:agent))).to include('name' => role.name, 'note' => 'hello')
    end

    it 'exposes all attributes to an admin' do
      expect(attributes_for_user(create(:admin))).to include('name' => role.name, 'note' => 'hello')
    end
  end
end
