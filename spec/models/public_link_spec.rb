# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe PublicLink, type: :model do
  it_behaves_like 'ApplicationModel'

  context 'when validating URLs' do
    it 'raises no exception for a valid link' do
      expect { create(:public_link) }.not_to raise_error
    end

    it 'raises an exception for an invalid link' do
      expect { create(:public_link, link: 'invalid') }.to raise_error(Exceptions::UnprocessableEntity)
    end
  end

  context 'when updating prios' do
    let(:links) do
      first_link  = create(:public_link, prio: 1)
      second_link = create(:public_link, prio: 2)
      third_link  = create(:public_link, prio: 3)

      {
        first:  first_link,
        second: second_link,
        third:  third_link,
      }
    end

    it 'rearranges the prios', :aggregate_failures do
      links[:third].update!(prio: 1)

      link_ids = described_class.all.order(prio: :asc).pluck(:id)

      expect(link_ids.first).to eq(links[:third].id)
      expect(link_ids.second).to eq(links[:first].id)
      expect(link_ids.third).to eq(links[:second].id)
    end
  end
end
