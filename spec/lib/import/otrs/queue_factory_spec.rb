# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/factory_examples'

RSpec.describe Import::OTRS::QueueFactory do
  it_behaves_like 'Import::Factory'

  def load_queue_json(file)
    json_fixture("import/otrs/queue/#{file}")
  end

  context 'when parent and child queues are imported' do
    let(:parent_queue) { load_queue_json('default') }
    let(:child_queue)  { load_queue_json('child') }

    it 'sorts queues by name and imports successfully', :aggregate_failures do
      expect(described_class.import([child_queue, parent_queue])).to include(
        hash_including('Name' => parent_queue['Name']),
        hash_including('Name' => child_queue['Name'])
      )

      expect(Group.find_by(name: parent_queue['Name'])).to be_present
      expect(Group.find_by(name: child_queue['Name'])).to be_present
    end
  end
end
