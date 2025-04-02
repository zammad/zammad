# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::Overview::UpdateOrder, current_user_id: 1 do
  subject(:service) { described_class.new(user, overviews) }

  let(:user) { create(:agent) }

  let(:overview_1) { create(:overview, prio: 1) }
  let(:overview_2) { create(:overview, prio: 2) }
  let(:overview_3) { create(:overview, prio: 3) }
  let(:overview_4) { create(:overview, prio: 4) }

  before do
    Overview.destroy_all

    [overview_1, overview_2, overview_3, overview_4].each do |elem|
      elem.users << user
    end
  end

  context 'when no custom sorting exists beforehand' do
    context 'when all overviews given' do
      let(:overviews) { [overview_3, overview_2, overview_1, overview_4] }

      it 'sets priorities' do
        service.execute

        expect(user.overview_sortings).to contain_exactly(
          have_attributes(overview: overview_1, prio: 2),
          have_attributes(overview: overview_2, prio: 1),
          have_attributes(overview: overview_3, prio: 0),
          have_attributes(overview: overview_4, prio: 3),
        )
      end
    end

    context 'when some overviews given' do
      let(:overviews) { [overview_3, overview_2, overview_1] }

      it 'sets given priorities' do
        service.execute

        expect(user.overview_sortings).to contain_exactly(
          have_attributes(overview: overview_1, prio: 2),
          have_attributes(overview: overview_2, prio: 1),
          have_attributes(overview: overview_3, prio: 0),
        )
      end

      it 'has no custom priority for item that was not given' do
        service.execute

        expect(user.overview_sortings.where(user:, overview: overview_4)).not_to be_exists
      end
    end
  end

  context 'when custom sorting exists beforehand' do
    before do
      create(:user_overview_sorting, overview: overview_1, prio: 4, user:)
      create(:user_overview_sorting, overview: overview_2, prio: 3, user:)
      create(:user_overview_sorting, overview: overview_3, prio: 2, user:)
      create(:user_overview_sorting, overview: overview_4, prio: 1, user:)
    end

    context 'when all overviews given' do
      let(:overviews) { [overview_3, overview_2, overview_1, overview_4] }

      it 'sets priorities' do
        service.execute

        expect(user.overview_sortings).to contain_exactly(
          have_attributes(overview: overview_1, prio: 2),
          have_attributes(overview: overview_2, prio: 1),
          have_attributes(overview: overview_3, prio: 0),
          have_attributes(overview: overview_4, prio: 3),
        )
      end
    end

    context 'when some overviews given' do
      let(:overviews) { [overview_3, overview_2, overview_1] }

      it 'sets given priorities' do
        service.execute

        expect(user.overview_sortings).to contain_exactly(
          have_attributes(overview: overview_1, prio: 2),
          have_attributes(overview: overview_2, prio: 1),
          have_attributes(overview: overview_3, prio: 0),
        )
      end

      it 'has no custom priority for item that was not given' do
        service.execute

        expect(user.overview_sortings.where(user:, overview: overview_4)).not_to be_exists
      end
    end
  end
end
