require 'rails_helper'

RSpec.shared_examples 'lookup backend' do
  it 'responds to for' do
    expect(described_class).to respond_to(:for)
  end
end
