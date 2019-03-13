require 'rails_helper'

RSpec.shared_examples 'a validation without errors' do
  it 'validatates without errors' do
    subject.validate
    expect(record.errors).to be_blank
  end
end

RSpec.shared_examples 'a validation with errors' do
  it 'validates with errors' do
    subject.validate
    expect(record.errors).to be_present
  end
end
