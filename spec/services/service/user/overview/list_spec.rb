# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::Overview::List do
  subject(:service) { described_class.new(user) }

  let(:user) { create(:agent) }

  let(:overview_1) { create(:overview, prio: 1) }
  let(:overview_2) { create(:overview, prio: 4) }
  let(:overview_3) { create(:overview, prio: 3) }
  let(:overview_4) { create(:overview, prio: 2) }

  before do
    Overview.destroy_all

    [overview_1, overview_2, overview_3, overview_4].each do |elem|
      elem.users << user
    end
  end

  context 'when no custom sorting exists' do
    it 'returns overviews in correct order' do
      expect(service.execute).to eq([overview_1, overview_4, overview_3, overview_2])
    end
  end

  context 'when custom sorting exists' do
    before do
      create(:user_overview_sorting, overview: overview_1, prio: 2, user:)
      create(:user_overview_sorting, overview: overview_2, prio: 1, user:)
      create(:user_overview_sorting, overview: overview_3, prio: 3, user:)
      create(:user_overview_sorting, overview: overview_4, prio: 4, user:)
    end

    it 'returns overviews in correct order' do
      expect(service.execute).to eq([overview_2, overview_1, overview_3, overview_4])
    end
  end

  context 'when some overviews are custom sorted' do
    before do
      create(:user_overview_sorting, overview: overview_2, prio: 3, user:)
      create(:user_overview_sorting, overview: overview_4, prio: 2, user:)
    end

    it 'returns overviews in correct order' do
      expect(service.execute).to eq([overview_4, overview_2, overview_1, overview_3])
    end
  end
end
