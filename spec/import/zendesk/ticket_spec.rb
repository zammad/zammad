require 'rails_helper'

# required due to some of rails autoloading issues
require 'import/zendesk/ticket'

RSpec.describe Import::Zendesk::Ticket do

  it 'creates' do

    ticket = double(
      id:                1337,
      subject:           'The ticket title',
      description:       'An example ticket',
      assignee:          69,
      requester_id:      42,
      group_id:          909,
      organization_id:   101,
      due_at:            DateTime.tomorrow,
      updated_at:        DateTime.yesterday,
      created_at:        DateTime.yesterday,
      tags:              [],
      comments:          [],
      custom_fields:     [],
    )

    local_user_id = 23

    expected_structure = {
      id:                       ticket.id,
      title:                    ticket.subject,
      note:                     ticket.description,
      group_id:                 3,
      owner_id:                 101,
      customer_id:              local_user_id,
      organization_id:          89,
      state:                    13,
      priority:                 7,
      pending_time:             ticket.due_at,
      updated_at:               ticket.updated_at,
      created_at:               ticket.created_at,
      updated_by_id:            local_user_id,
      created_by_id:            local_user_id,
      create_article_sender_id: 21,
      create_article_type_id:   555,
    }

    expect(Import::Zendesk::UserFactory).to receive(:local_id).with( ticket.requester_id ).and_return(local_user_id)
    expect(Import::Zendesk::UserFactory).to receive(:local_id).with( ticket.assignee ).and_return(expected_structure[:owner_id])

    expect(Import::Zendesk::GroupFactory).to receive(:local_id).with( ticket.group_id ).and_return(expected_structure[:group_id])
    expect(Import::Zendesk::OrganizationFactory).to receive(:local_id).with( ticket.organization_id ).and_return(expected_structure[:organization_id])
    expect(Import::Zendesk::Priority).to receive(:lookup).with(ticket).and_return(expected_structure[:priority])
    expect(Import::Zendesk::State).to receive(:lookup).with(ticket).and_return(expected_structure[:state])
    expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(expected_structure[:create_article_sender_id])
    expect(Import::Zendesk::Ticket::Comment::Type).to receive(:local_id).with(ticket).and_return(expected_structure[:create_article_type_id])

    local_ticket = double()

    expect(Import::Zendesk::Ticket::TagFactory).to receive(:import).with(ticket.tags, local_ticket, ticket)
    expect(Import::Zendesk::Ticket::CommentFactory).to receive(:import).with(ticket.comments, local_ticket, ticket)

    expect(::Ticket).to receive(:find_by).with(id: expected_structure[:id])
    expect(::Ticket).to receive(:create).with(expected_structure).and_return(local_ticket)

    expect_any_instance_of(described_class).to receive(:reset_primary_key_sequence)

    created_instance = described_class.new(ticket)
  end

  it 'updates' do

    ticket = double(
      id:                1337,
      subject:           'The ticket title',
      description:       'An example ticket',
      assignee:          69,
      requester_id:      42,
      group_id:          909,
      organization_id:   101,
      due_at:            DateTime.tomorrow,
      updated_at:        DateTime.yesterday,
      created_at:        DateTime.yesterday,
      tags:              [],
      comments:          [],
      custom_fields:     [],
    )

    local_user_id = 23

    expected_structure = {
      id:                       ticket.id,
      title:                    ticket.subject,
      note:                     ticket.description,
      group_id:                 3,
      owner_id:                 101,
      customer_id:              local_user_id,
      organization_id:          89,
      state:                    13,
      priority:                 7,
      pending_time:             ticket.due_at,
      updated_at:               ticket.updated_at,
      created_at:               ticket.created_at,
      updated_by_id:            local_user_id,
      created_by_id:            local_user_id,
      create_article_sender_id: 21,
      create_article_type_id:   555,
    }

    expect(Import::Zendesk::UserFactory).to receive(:local_id).with( ticket.requester_id ).and_return(local_user_id)
    expect(Import::Zendesk::UserFactory).to receive(:local_id).with( ticket.assignee ).and_return(expected_structure[:owner_id])

    expect(Import::Zendesk::GroupFactory).to receive(:local_id).with( ticket.group_id ).and_return(expected_structure[:group_id])
    expect(Import::Zendesk::OrganizationFactory).to receive(:local_id).with( ticket.organization_id ).and_return(expected_structure[:organization_id])
    expect(Import::Zendesk::Priority).to receive(:lookup).with(ticket).and_return(expected_structure[:priority])
    expect(Import::Zendesk::State).to receive(:lookup).with(ticket).and_return(expected_structure[:state])
    expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(expected_structure[:create_article_sender_id])
    expect(Import::Zendesk::Ticket::Comment::Type).to receive(:local_id).with(ticket).and_return(expected_structure[:create_article_type_id])

    local_ticket = double()

    expect(Import::Zendesk::Ticket::TagFactory).to receive(:import).with(ticket.tags, local_ticket, ticket)
    expect(Import::Zendesk::Ticket::CommentFactory).to receive(:import).with(ticket.comments, local_ticket, ticket)

    expect(::Ticket).to receive(:find_by).with(id: expected_structure[:id]).and_return(local_ticket)
    expect(local_ticket).to receive(:update_attributes).with(expected_structure)

    created_instance = described_class.new(ticket)
  end
end
