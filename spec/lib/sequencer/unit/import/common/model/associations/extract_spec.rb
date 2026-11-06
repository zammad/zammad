# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::Model::Associations::Extract, sequencer: :unit do
  let(:mapped) { { login: 'hans', role_ids: [1, 2], organization_id: 3, unknown_ids: [4] } }

  it 'provides the associations' do
    expect(process(model_class: User, mapped: mapped)).to include(associations: { role_ids: [1, 2], organization_id: 3 })
  end

  it 'removes the associations from the mapped attributes' do
    process(model_class: User, mapped: mapped)
    expect(mapped).to eq(login: 'hans', unknown_ids: [4])
  end

  it 'reflects on the associations of a model class only once' do
    process(model_class: User, mapped: mapped.dup)
    allow(User).to receive(:reflect_on_all_associations).and_call_original

    process(model_class: User, mapped: mapped.dup)
    expect(User).not_to have_received(:reflect_on_all_associations)
  end
end
