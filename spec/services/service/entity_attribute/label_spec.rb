# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::EntityAttribute::Label, :aggregate_failures do
  let(:agent) { create(:agent) }

  def label(attribute, value, user: agent)
    described_class.with_current_user(user).execute(attribute:, value:)
  end

  it 'reads a stored value as a person does' do
    product = build(:object_manager_attribute_select, name: 'product', data_option_options: { 'cloud' => 'Zammad Cloud' })
    state   = ObjectManager::Attribute.get(object: 'Ticket', name: 'state_id')

    expect(label(product, 'cloud')).to eq('Zammad Cloud')
    expect(label(state, Ticket::State.lookup(name: 'closed').id)).to eq('closed')
    expect(label(product, '')).to be_nil
  end

  it 'names no user the reader may not see' do
    reviewer  = build(:object_manager_attribute_user_autocompletion, name: 'reviewer')
    customer  = create(:customer, firstname: 'Rita', lastname: 'Reviewer')
    other     = create(:customer, organization: create(:organization))

    expect(label(reviewer, customer.id)).to eq('Rita Reviewer')
    expect(label(reviewer, customer.id, user: other)).to be_nil
  end
end
