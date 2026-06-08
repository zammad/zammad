# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Item::Destroy do
  subject(:service_result) { described_class.execute(object_id: object.id, object_name: object.class.name) }

  let(:object) { create(:ticket) }

  before do
    setup_ai_provider('open_ai')
  end

  it 'destroys a vector database item' do
    expect_any_instance_of(AI::VectorDB)
      .to receive(:destroy)
      .with(object_id: object.id, object_name: object.class.name)

    service_result
  end
end
