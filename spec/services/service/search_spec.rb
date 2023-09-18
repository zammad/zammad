# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Search do
  describe '#models' do
    let(:search)                      { described_class.new(current_user: create(:agent)) }
    let(:models_with_direct_index)    { search.models(objects: Models.searchable, direct_search_index: true) }
    let(:models_without_direct_index) { search.models(objects: Models.searchable, direct_search_index: false) }

    it 'returns different models for different direct_search_index flags' do
      expect(models_with_direct_index).not_to be_intersect(models_without_direct_index)
    end
  end
end
