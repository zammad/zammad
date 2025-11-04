# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Item::Destroy do
  let(:object) { create(:ticket) }

  before do

    setup_ai_provider('open_ai')
  end

  it 'destroys a vector database item' do
    expect_any_instance_of(AI::VectorDB)
      .to receive(:destroy)
      .with(object_id: object.id, object_name: object.class.name)

    described_class
      .new(object_id: object.id, object_name: object.class.name)
      .execute
  end
end
