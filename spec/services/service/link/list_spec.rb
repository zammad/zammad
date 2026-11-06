# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Link::List, :aggregate_failures do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, group:) }

  def list(target_type = 'Ticket', user: agent)
    described_class.with_current_user(user).execute(object: ticket, target_type:)
  end

  def query_count
    count    = 0
    callback = ->(*, payload) { count += 1 if !payload[:cached] && payload[:name] != 'SCHEMA' }

    Auth::RequestCache.clear
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { list }
    count
  end

  describe 'linked tickets' do
    let(:parent) { create(:ticket, group:) }
    let(:child)  { create(:ticket, group:) }
    let(:other)  { create(:ticket, group:) }

    # A parent link is stored from the parent to its child; the list names it from the listed ticket's side.
    before do
      create(:link, from: parent, to: ticket, link_type: 'parent')
      create(:link, from: ticket, to: child, link_type: 'parent')
      create(:link, from: other, to: ticket, link_type: 'normal')
    end

    it 'lists them with how each is linked to the ticket' do
      expect(list).to contain_exactly(
        { item: parent, type: 'parent' },
        { item: child, type: 'child' },
        { item: other, type: 'normal' },
      )
    end

    it 'leaves out a ticket the user may not see' do
      create(:link, from: create(:ticket), to: ticket)

      expect(list.pluck(:item)).to contain_exactly(parent, child, other)
    end

    it 'leaves out a link whose ticket is gone' do
      create(:link, from: build_stubbed(:ticket), to: ticket)

      expect(list.pluck(:item)).to contain_exactly(parent, child, other)
    end

    it 'costs no more queries for 30 linked tickets than for 3' do
      # The first call fills caches that live longer than a request.
      query_count

      expect { create_list(:ticket, 27, group:).each { |linked| create(:link, from: linked, to: ticket) } }
        .not_to change { query_count }
    end
  end

  describe 'linked knowledge base answers' do
    let(:published) { create(:knowledge_base_answer, :published) }
    let(:draft)     { create(:knowledge_base_answer, :draft) }

    before do
      create(:link, from: ticket, to: published.translations.first)
      create(:link, from: ticket, to: draft.translations.first)
    end

    it 'lists the answers the user may see' do
      expect(list('KnowledgeBase::Answer::Translation')).to eq([{ item: published.translations.first, type: 'normal' }])
    end
  end
end
