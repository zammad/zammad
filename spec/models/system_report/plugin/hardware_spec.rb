# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SystemReport::Plugin::Hardware, current_user_id: 1, type: :model do
  it 'does calculate total memory' do
    expect(described_class.new.fetch['total_memory'].class).to eq(Integer)
  end

  it 'does also work when the open result is an array #5402', :aggregate_failures do
    instance = described_class.new
    result = described_class.new.send(:execute)
    allow(instance).to receive(:execute).and_return(Array.wrap(result))
    expect { instance.fetch }.not_to raise_error
  end
end
