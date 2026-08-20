# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Group::Assets do
  subject(:group) { create(:group) }

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
  end
end
