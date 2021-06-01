# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'TagWritesToTicketHistory' do
  subject { create(described_class.name.underscore) }

  # The concern is for the tag model, but the shared example needs to be loaded in the ticket test.
  it 'can only be loaded for tickets' do
    expect(described_class).to eq Ticket
  end

  it 'creates a ticket history entry for tag_add' do # rubocop:disable RSpec/ExampleLength
    subject.tag_add('foo', 1)
    expect(subject.history_get.last).to include(
      'object'     => described_class.name,
      'o_id'       => subject.id,
      'type'       => 'added',
      'attribute'  => 'tag',
      'value_to'   => 'foo',
      'value_from' => nil
    )
  end

  it 'creates a ticket history entry for tag_remove' do # rubocop:disable RSpec/ExampleLength
    subject.tag_add('foo', 1)
    subject.tag_remove('foo', 1)
    expect(subject.history_get.last).to include(
      'object'     => described_class.name,
      'o_id'       => subject.id,
      'type'       => 'removed',
      'attribute'  => 'tag',
      'value_to'   => 'foo',
      'value_from' => nil
    )
  end
end
