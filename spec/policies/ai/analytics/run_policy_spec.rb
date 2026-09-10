# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe AI::Analytics::RunPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:record)         { create(:ai_analytics_run, related_object:) }
  let(:related_object) { nil }

  context 'when user is agent' do
    let(:user) { create(:agent) }

    context 'when related object is ticket' do
      let(:related_object) { create(:ticket, group:) }
      let(:group)          { create(:group) }

      before { user.groups << group }

      it { is_expected.to permit_all_actions }
    end

    context 'when no related object' do
      it { is_expected.to permit_all_actions }
    end

    context 'when related object is a ticket article' do
      let(:related_object) { create(:ticket_article, ticket: create(:ticket, group:)) }
      let(:group)          { create(:group) }

      context 'when the user has access to the article\'s ticket' do
        before { user.groups << group }

        it { is_expected.to permit_all_actions }
      end

      context 'when the user has no access to the article\'s ticket' do
        it { is_expected.to forbid_all_actions }
      end

      context 'when the article was merged into a ticket of another group' do
        let(:target_group)  { create(:group) }
        let(:target_ticket) { create(:ticket, group: target_group) }

        before do
          user.groups << target_group

          UserInfo.current_user_id = 1
          related_object.ticket.merge_to(ticket_id: target_ticket.id, user_id: 1)
          related_object.reload
        end

        it 'authorizes through the ticket the article belongs to now' do
          expect(policy).to permit_all_actions
        end
      end

      context 'when the article was merged away from the group the user has' do
        let(:target_ticket) { create(:ticket, group: create(:group)) }

        before do
          user.groups << group

          UserInfo.current_user_id = 1
          related_object.ticket.merge_to(ticket_id: target_ticket.id, user_id: 1)
          related_object.reload
        end

        it 'no longer authorizes through the ticket it came from' do
          expect(policy).to forbid_all_actions
        end
      end
    end
  end

  context 'when user is customer' do
    let(:user) { create(:customer) }

    context 'when related object is ticket' do
      let(:related_object) { create(:ticket, customer: user) }

      it { is_expected.to forbid_all_actions }
    end

    context 'when no related object' do
      it { is_expected.to forbid_all_actions }
    end
  end
end
