require 'rails_helper'

# required due to some of rails autoloading issues
require 'import/zendesk/ticket/tag'

RSpec.describe Import::Zendesk::Ticket::Tag do

  it 'creates ticket tags' do

    tag = double(id: 'Test Tag')

    local_ticket = instance_double(::Ticket, id: 1337)

    zendesk_ticket = double(requester_id: 31_337)

    expect(Import::Zendesk::UserFactory).to receive(:local_id).with(zendesk_ticket.requester_id)
    expect(::Tag).to receive(:tag_add).with(hash_including(item: tag.id, o_id: local_ticket.id))

    described_class.new(tag, local_ticket, zendesk_ticket)
  end
end
