# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.shared_examples 'a validation without errors' do
  it 'validatates without errors' do
    allow(subject).to receive(:value).and_return(value) # rubocop:disable RSpec/SubjectStub
    subject.validate
    expect(record.errors).to be_blank
  end
end

RSpec.shared_examples 'a validation with errors' do
  it 'validates with errors' do
    allow(subject).to receive(:value).and_return(value) # rubocop:disable RSpec/SubjectStub
    subject.validate
    expect(record.errors).to be_present
  end
end

RSpec.shared_examples 'validate backend' do
  it 'included in backends list' do
    expect(::ObjectManager::Attribute::Validation.backends).to include(described_class)
  end
end
