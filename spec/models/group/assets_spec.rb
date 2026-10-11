# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Group::Assets do
  subject(:group) { create(:group, note: 'hello', parent: create(:group)) }

  def attributes_for_user(user)
    UserInfo.with_user_id(user.id) { group.attributes_with_association_ids }
  end

  describe '#authorized_asset?' do
    context 'without a user context' do
      before { UserInfo.reset }

      it { is_expected.not_to be_authorized_asset }

      it 'is authorized in a system context' do
        UserInfo.with_system_context do
          expect(group).to be_authorized_asset
        end
      end
    end

    context 'with an agent of the group' do
      before { UserInfo.current_user_id = create(:agent, groups: [group]).id }

      it { is_expected.to be_authorized_asset }
    end
  end

  describe '#assets' do
    # Without a context the group used to end up in the payload unconditionally, together with
    # its unredacted attributes.
    it 'excludes the group without a user context' do
      UserInfo.reset

      expect(group.assets({})).not_to include(Group.to_app_model => hash_including(group.id))
    end

    it 'includes the group in a system context' do
      expect(UserInfo.with_system_context { group.assets({}) })
        .to include(Group.to_app_model => hash_including(group.id))
    end
  end

  describe '#filter_unauthorized_attributes' do
    it 'redacts internal attributes without a user context' do
      UserInfo.reset

      expect(group.attributes_with_association_ids.keys).not_to include('note', 'user_ids')
    end

    it 'exposes only the public attributes to a customer' do
      expect(attributes_for_user(create(:customer)))
        .to include('id' => group.id, 'name' => group.name, 'name_last' => group.name_last, 'parent_id' => group.parent_id)
        .and not_include('note', 'email_address_id', 'signature_id', 'user_ids')
    end

    it 'exposes all attributes to an agent' do
      expect(attributes_for_user(create(:agent))).to include('note' => 'hello', 'email_address_id' => group.email_address_id)
    end

    it 'exposes all attributes to an admin' do
      expect(attributes_for_user(create(:admin))).to include('note' => 'hello')
    end
  end
end
