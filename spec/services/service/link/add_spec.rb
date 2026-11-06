# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Link::Add, :aggregate_failures do
  let(:ticket) { create(:ticket) }
  let(:other)  { create(:ticket) }

  def named_from(object, item)
    Link.list(link_object: object.class.name, link_object_value: object.id)
      .find { |link| link['link_object_value'] == item.id }&.fetch('link_type')
  end

  it 'links the source to the target as what the source is to it, read so from both sides' do
    described_class.execute(source: other, target: ticket, type: 'parent')

    expect(named_from(ticket, other)).to eq('parent')
    expect(named_from(other, ticket)).to eq('child')
    expect(Service::Link::List.with_current_user(create(:agent, groups: [ticket.group, other.group])).execute(object: ticket, target_type: 'Ticket'))
      .to contain_exactly({ item: other, type: 'parent' })
  end

  it 'refuses a second link between the two, in either direction or of another kind, naming the kind it has' do
    described_class.execute(source: other, target: ticket, type: 'parent')

    [
      { source: other, target: ticket, type: 'parent' },
      { source: other, target: ticket, type: 'normal' },
      { source: ticket, target: other, type: 'child' },
      { source: ticket, target: other, type: 'normal' },
    ].each do |arguments|
      expect { described_class.execute(**arguments) }.to raise_error(described_class::LinkedAlready, 'Link already exists') { |error|
        expect(error.type).to eq(arguments[:source] == other ? 'parent' : 'child')
      }
    end
    expect(Link.count).to eq(1)
  end

  it 'refuses a ticket linked to itself' do
    expect { described_class.execute(source: ticket, target: ticket, type: 'normal') }
      .to raise_error(Exceptions::UnprocessableContent, 'An object cannot be linked to itself.')
    expect(Link.count).to eq(0)
  end

  it 'links a knowledge base answer as well' do
    translation = create(:knowledge_base_answer, :published).translations.first

    expect { described_class.execute(source: translation, target: ticket, type: 'normal') }.to change(Link, :count).by(1)
  end

  context 'when two calls link the same two objects at once', :ensure_threads_exited do
    self.use_transactional_tests = false

    include_context 'with a link call that pauses after looking for an existing link'

    # Committed, so without the email address and channel a group's factory adds.
    let(:ticket) { create(:ticket, group: create(:group, email_address: nil)) }
    let(:other)  { create(:ticket, group: create(:group, email_address: nil)) }

    after do
      customers = [ticket.customer_id, other.customer_id]
      groups    = [ticket.group_id, other.group_id]
      Link.where(link_object_source_value: [ticket.id, other.id]).delete_all
      Ticket.where(id: [ticket.id, other.id]).destroy_all
      User.where(id: customers).destroy_all
      Group.where(id: groups).destroy_all
    end

    def linking(**) = -> { described_class.execute(**) }

    it 'saves one link where both link them in the same direction, and refuses the second call with it' do
      first, second = link_concurrently(linking(source: other, target: ticket, type: 'child'), linking(source: other, target: ticket, type: 'normal'))

      expect(first).to be_a(Link)
      expect(second).to be_a(described_class::LinkedAlready).and(have_attributes(type: 'child'))
      expect(Link.where(link_object_source_value: [ticket.id, other.id]).count).to eq(1)
    end

    it 'saves one link of a ticket and a knowledge base answer that both views link the other way round' do
      translation = create(:knowledge_base_answer, :published).translations.first
      first, second = link_concurrently(linking(source: translation, target: ticket, type: 'normal'), linking(source: ticket, target: translation, type: 'normal'))

      expect(first).to be_a(Link)
      expect(second).to be_a(described_class::LinkedAlready)
      expect(Link.where(link_object_source_value: [ticket.id, translation.id]).count).to eq(1)
    ensure
      Link.where(link_object_source_value: [ticket.id, translation&.id]).delete_all
      translation&.answer&.category&.knowledge_base&.full_destroy!
    end

    it 'saves one link where they link them the other way round, and refuses the second call with it' do
      first, second = link_concurrently(linking(source: other, target: ticket, type: 'parent'), linking(source: ticket, target: other, type: 'normal'))

      expect(first).to be_a(Link)
      expect(second).to be_a(described_class::LinkedAlready).and(have_attributes(type: 'child'))
      expect(Link.where(link_object_source_value: [ticket.id, other.id]).count).to eq(1)
    end
  end
end
