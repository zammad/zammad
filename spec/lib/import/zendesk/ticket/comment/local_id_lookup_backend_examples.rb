require 'rails_helper'

RSpec.shared_examples 'local_id lookup backend' do
  it 'responds to local_id' do
    expect(described_class).to respond_to(:local_id)
  end
end
