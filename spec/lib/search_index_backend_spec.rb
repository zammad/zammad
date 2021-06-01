# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SearchIndexBackend, searchindex: true do

  before do
    configure_elasticsearch
    rebuild_searchindex
  end

  describe '.build_query' do
    subject(:query) { described_class.build_query('', query_extension: params) }

    let(:params) { { 'bool' => { 'filter' => { 'term' => { 'a' => 'b' } } } } }

    it 'coerces :query_extension hash keys to symbols' do
      expect(query.dig(:query, :bool, :filter, :term, :a)).to eq('b')
    end
  end

  describe '.search' do

    context 'query finds results' do

      let(:record_type) { 'Ticket'.freeze }
      let(:record) { create :ticket }

      before do
        described_class.add(record_type, record)
        described_class.refresh
      end

      it 'finds added records' do
        result = described_class.search(record.number, record_type, sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: record.id.to_s, type: record_type }])
      end
    end

    context 'for query with no results' do
      subject(:search) { described_class.search(query, index, limit: 3000) }

      let(:query) { 'preferences.notification_sound.enabled:*' }

      context 'on a single index' do
        let(:index) { 'User' }

        it { is_expected.to be_an(Array).and be_empty }
      end

      context 'on multiple indices' do
        let(:index) { %w[User Organization] }

        it { is_expected.to be_an(Array).and not_include(nil).and be_empty }
      end
    end
  end

  describe '.append_wildcard_to_simple_query' do
    context 'with "simple" queries' do
      let(:queries) { <<~QUERIES.lines.map { |x| x.split('#')[0] }.map(&:strip) }
        M
        Max
        Max. # dot and underscore are acceptable characters in simple queries
        A_
        A_B
        äöü
        123
        *ax  # wildcards are allowed in simple queries
        Max*
        M*x
        M?x
        test@example.com
        test@example.
        test@example
        test@
      QUERIES

      it 'appends a * to the original query' do
        expect(queries.map { |query| described_class.append_wildcard_to_simple_query(query) })
          .to eq(queries.map { |q| "#{q}*" })
      end
    end

    context 'with "complex" queries (using search operators)' do
      let(:queries) { <<~QUERIES.lines.map { |x| x.split('#')[0] }.map(&:strip) }
        title:"some words with spaces" # exact phrase / without quotation marks " an AND search for the words will be performed (in Zammad 1.5 and lower an OR search will be performed)
        title:"some wor*" # exact phrase beginning with "some wor*" will be searched
        created_at:[2017-01-01 TO 2017-12-31] # a time range
        created_at:>now-1h # created within last hour
        state:new OR state:open
        (state:new OR state:open) OR priority:"3 normal"
        (state:new OR state:open) AND customer.lastname:smith
        state:(new OR open) AND title:(full text search) # state: new OR open & title: full OR text OR search
        tags: "some tag"
        owner.email: "bod@example.com" AND state: (new OR open OR pending*) # show all open tickets of a certain agent
        state:closed AND _missing_:tag # all closed objects without tags
        article_count: [1 TO 5] # tickets with 1 to 5 articles
        article_count: [10 TO *] # tickets with 10 or more articles
        article.from: bob # also article.from can be used
        article.body: heat~ # using the fuzzy operator will also find terms that are similar, in this case also "head"
        article.body: /joh?n(ath[oa]n)/ # using regular expressions
        user:M
        user:Max
        user:Max.
        user:Max*
        organization:A_B
        organization:A_B*
        user: M
        user: Max
        user: Max.
        user: Max*
        organization: A_B
        organization: A_B*
        id:123
        number:123
        id:"123"
        number:"123"
      QUERIES

      it 'returns the original query verbatim' do
        expect(queries.map { |query| described_class.append_wildcard_to_simple_query(query) })
          .to eq(queries)
      end
    end
  end

  describe '.remove' do
    context 'record gets deleted' do

      let(:record_type) { 'Ticket'.freeze }
      let(:deleted_record) { create :ticket }

      before do
        described_class.add(record_type, deleted_record)
        described_class.refresh
      end

      it 'removes record from search index' do
        described_class.remove(record_type, deleted_record.id)
        described_class.refresh

        result = described_class.search(deleted_record.number, record_type, sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([])
      end

      context 'other records present' do

        let(:other_record) { create :ticket }

        before do
          described_class.add(record_type, other_record)
          described_class.refresh
        end

        it "doesn't remove other records" do
          described_class.remove(record_type, deleted_record.id)
          described_class.refresh

          result = described_class.search(other_record.number, record_type, sort_by: ['updated_at'], order_by: ['desc'])
          expect(result).to eq([{ id: other_record.id.to_s, type: record_type }])
        end
      end
    end
  end

  describe '.selectors' do

    let(:group1) { create :group }
    let(:organization1) { create :organization, note: 'hihi' }
    let(:agent1) { create :agent, organization: organization1, groups: [group1] }
    let(:customer1) { create :customer, organization: organization1, firstname: 'special-first-name' }
    let(:ticket1) do
      ticket = create :ticket, title: 'some-title1', state_id: 1, created_by: agent1
      ticket.tag_add('t1', 1)
      ticket
    end
    let(:ticket2) do
      ticket = create :ticket, title: 'some_title2', state_id: 4
      ticket.tag_add('t2', 1)
      ticket
    end
    let(:ticket3) do
      ticket = create :ticket, title: 'some::title3', state_id: 1
      ticket.tag_add('t1', 1)
      ticket.tag_add('t2', 1)
      ticket
    end
    let(:ticket4) { create :ticket, title: 'phrase some-title4', state_id: 1 }
    let(:ticket5) { create :ticket, title: 'phrase some_title5', state_id: 1 }
    let(:ticket6) { create :ticket, title: 'phrase some::title6', state_id: 1 }
    let(:ticket7) { create :ticket, title: 'some title7', state_id: 1 }
    let(:ticket8) { create :ticket, title: 'sometitle', group: group1, state_id: 1, owner: agent1, customer: customer1, organization: organization1 }
    let(:article8) { create :ticket_article, ticket: ticket8, subject: 'lorem ipsum' }

    before do
      Ticket.destroy_all # needed to remove not created tickets
      travel(-1.hour)
      create(:mention, mentionable: ticket1, user: agent1)
      ticket1.search_index_update_backend
      travel 1.hour
      ticket2.search_index_update_backend
      travel 1.second
      ticket3.search_index_update_backend
      travel 1.second
      ticket4.search_index_update_backend
      travel 1.second
      ticket5.search_index_update_backend
      travel 1.second
      ticket6.search_index_update_backend
      travel 1.second
      ticket7.search_index_update_backend
      travel 1.hour
      article8.ticket.search_index_update_backend
      described_class.refresh
    end

    context 'query with contains' do
      it 'finds records with till (relative)' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.created_at'=>{ 'operator' => 'till (relative)', 'value' => '30', 'range' => 'minute' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with from (relative)' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.created_at'=>{ 'operator' => 'from (relative)', 'value' => '30', 'range' => 'minute' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
      end

      it 'finds records with till (relative) including +1 hour ticket' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.created_at'=>{ 'operator' => 'till (relative)', 'value' => '120', 'range' => 'minute' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 8, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with from (relative) including -1 hour ticket' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.created_at'=>{ 'operator' => 'from (relative)', 'value' => '120', 'range' => 'minute' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 8, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with tags which contains all' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.tags'=>{ 'operator' => 'contains all', 'value' => 't1, t2' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket3.id.to_s] })
      end

      it 'finds records with tags which contains one' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.tags'=>{ 'operator' => 'contains one', 'value' => 't1, t2' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 3, ticket_ids: [ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with tags which contains all not' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.tags'=>{ 'operator' => 'contains all not', 'value' => 't2' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 6, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with tags which contains one not' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.tags'=>{ 'operator' => 'contains one not', 'value' => 't1' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 6, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket2.id.to_s] })
      end

      it 'finds records with organization note' do
        result = described_class.selectors('Ticket',
                                           {
                                             'organization.note' => {
                                               'operator' => 'contains',
                                               'value'    => 'hihi',
                                             },
                                           },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket8.id.to_s] })
      end

      it 'finds records with customer firstname' do
        result = described_class.selectors('Ticket',
                                           {
                                             'customer.firstname' => {
                                               'operator' => 'contains',
                                               'value'    => 'special',
                                             },
                                           },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket8.id.to_s] })
      end

      it 'finds records with article subject' do
        result = described_class.selectors('Ticket',
                                           {
                                             'article.subject' => {
                                               'operator' => 'contains',
                                               'value'    => 'ipsum',
                                             },
                                           },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket8.id.to_s] })
      end

      it 'finds records with pre_condition not_set' do
        result = described_class.selectors('Ticket',
                                           {
                                             'created_by_id' => {
                                               'pre_condition' => 'not_set',
                                               'operator'      => 'is',
                                             },
                                           },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
      end

      it 'finds records with pre_condition current_user.id' do
        result = described_class.selectors('Ticket',
                                           {
                                             'owner_id' => {
                                               'pre_condition' => 'current_user.id',
                                               'operator'      => 'is',
                                             },
                                           },
                                           { current_user: agent1 },
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket8.id.to_s] })
      end

      it 'finds records with pre_condition current_user.organization_id' do
        result = described_class.selectors('Ticket',
                                           {
                                             'organization_id' => {
                                               'pre_condition' => 'current_user.organization_id',
                                               'operator'      => 'is',
                                             },
                                           },
                                           { current_user: agent1 },
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket8.id.to_s] })
      end

      it 'finds records with containing phrase' do
        result = described_class.selectors('Ticket',
                                           {
                                             'title' => {
                                               'operator' => 'contains',
                                               'value'    => 'phrase',
                                             },
                                           },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 3, ticket_ids: [ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s] })
      end

      it 'finds records with containing some title7' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains',
                                             'value'    => 'some title7',
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket7.id.to_s] })
      end

      it 'finds records with containing -' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains',
                                             'value'    => 'some-title1',
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket1.id.to_s] })
      end

      it 'finds records with containing _' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains',
                                             'value'    => 'some_title2',
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket2.id.to_s] })
      end

      it 'finds records with containing ::' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains',
                                             'value'    => 'some::title3',
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket3.id.to_s] })
      end

      it 'finds records with containing 4' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'contains',
                                             'value'    => 4,
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket2.id.to_s] })
      end

      it 'finds records with containing "4"' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'contains',
                                             'value'    => '4',
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket2.id.to_s] })
      end
    end

    context 'query with contains not' do
      it 'finds records with containing not phrase' do
        result = described_class.selectors('Ticket',
                                           {
                                             'title' => {
                                               'operator' => 'contains not',
                                               'value'    => 'phrase',
                                             },
                                           },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 5, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with containing not some title7' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains not',
                                             'value'    => 'some title7',
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with containing not -' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains not',
                                             'value'    => 'some-title1',
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
      end

      it 'finds records with containing not _' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains not',
                                             'value'    => 'some_title2',
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with containing not ::' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains not',
                                             'value'    => 'some::title3',
                                           })

        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with containing not 4' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'contains not',
                                             'value'    => 4,
                                           })

        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with containing not "4"' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'contains not',
                                             'value'    => '4',
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket1.id.to_s] })
      end
    end

    context 'query with is' do
      it 'finds records with is phrase' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is',
                                             'value'    => 'phrase',
                                           })
        expect(result).to eq({ count: 0, ticket_ids: [] })
      end

      it 'finds records with is some title7' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is',
                                             'value'    => 'some title7',
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket7.id.to_s] })
      end

      it 'finds records with is -' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is',
                                             'value'    => 'some-title1',
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket1.id.to_s] })
      end

      it 'finds records with is _' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is',
                                             'value'    => 'some_title2',
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket2.id.to_s] })
      end

      it 'finds records with is ::' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is',
                                             'value'    => 'some::title3',
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket3.id.to_s] })
      end

      it 'finds records with is 4' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'is',
                                             'value'    => 4,
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket2.id.to_s] })
      end

      it 'finds records with is "4"' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'is',
                                             'value'    => '4',
                                           })

        expect(result).to eq({ count: 1, ticket_ids: [ticket2.id.to_s] })
      end
    end

    context 'query with is not' do
      it 'finds records with is not phrase' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is not',
                                             'value'    => 'phrase',
                                           })
        expect(result).to eq({ count: 8, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with is not some title7' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is not',
                                             'value'    => 'some title7',
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with is not -' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is not',
                                             'value'    => 'some-title1',
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
      end

      it 'finds records with is not _' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is not',
                                             'value'    => 'some_title2',
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with is not ::' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is not',
                                             'value'    => 'some::title3',
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with is not 4' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'is not',
                                             'value'    => 4,
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with is not "4"' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'is not',
                                             'value'    => '4',
                                           })

        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with is not state_id ["4"] and title ["sometitle"]' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'is not',
                                             'value'    => ['4'],
                                           },
                                           'title'    => {
                                             'operator' => 'is',
                                             'value'    => ['sometitle'],
                                           })

        expect(result).to eq({ count: 1, ticket_ids: [ticket8.id.to_s] })
      end

    end

    context 'mentions' do
      it 'finds records with pre_condition is not_set' do
        result = described_class.selectors('Ticket',
                                           {
                                             'ticket.mention_user_ids' => {
                                               'pre_condition' => 'not_set',
                                               'operator'      => 'is',
                                             },
                                           },
                                           { current_user: agent1 },
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
      end

      it 'finds records with pre_condition is not not_set' do
        result = described_class.selectors('Ticket',
                                           {
                                             'ticket.mention_user_ids' => {
                                               'pre_condition' => 'not_set',
                                               'operator'      => 'is not',
                                             },
                                           },
                                           { current_user: agent1 },
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket1.id.to_s] })
      end

      it 'finds records with pre_condition is current_user.id' do
        result = described_class.selectors('Ticket',
                                           {
                                             'ticket.mention_user_ids' => {
                                               'pre_condition' => 'current_user.id',
                                               'operator'      => 'is',
                                             },
                                           },
                                           { current_user: agent1 },
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket1.id.to_s] })
      end

      it 'finds records with pre_condition is not current_user.id' do
        result = described_class.selectors('Ticket',
                                           {
                                             'ticket.mention_user_ids' => {
                                               'pre_condition' => 'current_user.id',
                                               'operator'      => 'is not',
                                             },
                                           },
                                           { current_user: agent1 },
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
      end

      it 'finds records with pre_condition is specific' do
        result = described_class.selectors('Ticket',
                                           {
                                             'ticket.mention_user_ids' => {
                                               'pre_condition' => 'specific',
                                               'operator'      => 'is',
                                               'value'         => agent1.id,
                                             },
                                           },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 1, ticket_ids: [ticket1.id.to_s] })
      end

      it 'finds records with pre_condition is not specific' do
        result = described_class.selectors('Ticket',
                                           {
                                             'ticket.mention_user_ids' => {
                                               'pre_condition' => 'specific',
                                               'operator'      => 'is not',
                                               'value'         => agent1.id,
                                             },
                                           },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 7, ticket_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
      end
    end
  end
end
