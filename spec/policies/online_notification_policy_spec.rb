# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe OnlineNotificationPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:user) { create(:admin, groups: [Ticket.first.group]) }

  context 'when user is owner' do
    let(:record) { create(:online_notification, user: user) }

    it { is_expected.to permit_actions(%i[show destroy update]) }

    it 'returns true for show columns' do
      expect(policy.show?).to a_kind_of(TrueClass)
    end

    it 'grants access to the related object' do
      expect(policy.related_accessible?).to be(true)
    end
  end

  context 'when user is owner, but has no access to related object' do
    let(:record) { create(:online_notification, user: user, o: ticket) }
    let(:ticket) { create(:ticket) }

    it { is_expected.to permit_actions(%i[show destroy update]) }

    it 'returns permitted columns' do
      expect(policy.show?).to a_kind_of(ApplicationPolicy::FieldScope)
    end

    it 'denies access to the related object' do
      expect(policy.related_accessible?).to be(false)
    end
  end

  context 'when user is not owner' do
    let(:record) { create(:online_notification, user: create(:user)) }

    it { is_expected.to forbid_actions(%i[show destroy update]) }
  end

  context 'when using a standalone object' do
    let(:record) { create(:online_notification, :with_bulk_job, user:) }

    it { is_expected.to permit_actions(%i[show destroy update]) }

    it 'grants access to the related object' do
      expect(policy.related_accessible?).to be(true)
    end
  end

  describe '#related_accessible?' do
    let(:user)  { create(:agent, groups: [group]) }
    let(:group) { create(:group) }

    context 'with a ticket the user may read' do
      let(:record) { create(:online_notification, user:, o: create(:ticket, group:)) }

      it { expect(policy.related_accessible?).to be(true) }

      it 'authorizes a given related object instead of looking it up' do
        expect(policy.related_accessible?(create(:ticket, group: create(:group)))).to be(false)
      end
    end

    context 'with a ticket the user may only read as its customer' do
      let(:user)   { create(:agent_and_customer, groups: [group]) }
      let(:record) { create(:online_notification, user:, o: create(:ticket, group: create(:group), customer: user)) }

      it { expect(policy.related_accessible?).to be(false) }
    end

    context 'with an internal article of a ticket the user may not read' do
      let(:record) { create(:online_notification, user:, o: create(:ticket_article, ticket: create(:ticket, group: create(:group)), internal: true)) }

      it { expect(policy.related_accessible?).to be(false) }
    end

    context 'with a standalone object' do
      let(:record) { create(:online_notification, :with_bulk_job, user:) }

      it { expect(policy.related_accessible?).to be(true) }
    end

    context 'with a standalone object another user was notified about' do
      let(:foreign_notification) { create(:online_notification, :with_bulk_job, user: create(:agent)) }
      let(:record)               { create(:online_notification, o: foreign_notification.related_object, user:, type_name: 'bulk_job') }

      it { expect(policy.related_accessible?).to be(false) }
    end

    context 'with a published answer of a category the user may only read publicly' do
      let(:answer) { create(:knowledge_base_answer, :published) }
      let(:record) { create(:online_notification, user:, o: answer.translations.first, type_name: 'create') }

      before { create(:knowledge_base_permission, permissionable: answer.category, role: user.roles.first, access: 'none') }

      it { expect(policy.related_accessible?).to be(false) }
    end

    context 'when the related object no longer exists' do
      let(:record) { create(:online_notification, user:, object_lookup_id: ObjectLookup.by_name('Ticket'), o_id: 0) }

      it { expect(policy.related_accessible?).to be(false) }
    end

    context 'when the related object has no policy' do
      let(:record) { create(:online_notification, user:, o: ObjectLookup.first) }

      it { expect(policy.related_accessible?).to be(false) }
    end
  end
end
