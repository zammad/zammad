# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.shared_examples 'a validation without errors' do
  it 'validatates without errors' do
    allow(subject).to receive(:value).and_return(value)
    subject.validate
    expect(record.errors).to be_blank
  end
end

RSpec.shared_examples 'a validation with errors' do
  it 'validates with errors' do
    allow(subject).to receive(:value).and_return(value)
    subject.validate
    expect(record.errors).to be_present
  end
end

RSpec.shared_examples 'validate backend' do
  it 'included in backends list' do
    expect(Validations::ObjectManager::AttributeValidator.backends).to include(described_class)
  end
end
