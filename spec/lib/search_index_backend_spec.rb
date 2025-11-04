# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SearchIndexBackend do

  before do |example|
    next if !example.metadata[:searchindex]

    searchindex_model_reload([Ticket, User, Organization])
  end

  describe '.build_query' do
    subject(:query) { described_class.build_query('Ticket', '', query_extension: params) }

    let(:params) { { 'bool' => { 'filter' => { 'term' => { 'a' => 'b' } } } } }

    it 'coerces :query_extension hash keys to symbols' do
      expect(query.dig(:query, :bool, :filter, :term, :a)).to eq('b')
    end
  end

  describe '.search', searchindex: false do
    before do
      allow(described_class).to receive(:search_by_index) { |_query, index, _options| ["response:#{index}"] }
    end

    let(:query)   { Faker::Lorem.word }
    let(:options) { { opt1: true } }

    it 'calls search_by_index if single index given' do
      described_class.search(query, 'Index A', options)

      expect(described_class)
        .to have_received(:search_by_index)
        .with(query, 'Index A', options)
        .once
    end

    it 'calls search_by_index for each given index given', aggregate_failures: true do
      described_class.search(query, %w[indexA indexB], options)

      expect(described_class)
        .to have_received(:search_by_index)
        .with(query, 'indexA', options)
        .once

      expect(described_class)
        .to have_received(:search_by_index)
        .with(query, 'indexB', options)
        .once
    end

    it 'flattens results if multiple indexes are queries' do
      expect(described_class.search(query, %w[indexA indexB], options))
        .to eq %w[response:indexA response:indexB]
    end

    context 'when one of the indexes return nil' do
      before do
        allow(described_class).to receive(:search_by_index)
          .with(anything, 'empty', anything).and_return(nil)
      end

      it 'does not include nil in flattened return' do
        expect(described_class.search(query, %w[indexA empty indexB], options))
          .to eq %w[response:indexA response:indexB]
      end

      it 'returns nil if single index was queried' do
        expect(described_class.search(query, 'empty', options))
          .to be_nil
      end
    end

    it 'raises an error if with_total_count option is passed' do
      expect { described_class.search(query, %w[indexA indexB], { with_total_count: true }) }
        .to raise_error(include('with_total_count'))
    end
  end

  describe '.search_by_index', searchindex: true do
    context 'query finds results' do

      let(:record_type) { 'Ticket'.freeze }
      let(:record) { create(:ticket) }

      before do
        record.search_index_update_backend
        described_class.refresh
      end

      it 'finds added records' do
        result = described_class.search_by_index(record.number, record_type, sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: record.id.to_s, type: record_type }])
      end

      it 'returns count and id when with_total_count option is given' do
        result = described_class.search_by_index(record.number, record_type, with_total_count: true)
        expect(result).to include(
          total_count:     1,
          object_metadata: include(include(id: record.id.to_s))
        )
      end
    end

    context 'when search for user firstname + double lastname' do
      let(:record_type) { 'User'.freeze }
      let(:record) { create(:user, login: 'a', email: 'a@a.de', firstname: 'AnFirst', lastname: 'ASplit Lastname') }

      before do
        record.search_index_update_backend
        described_class.refresh
      end

      it 'finds user record' do
        result = described_class.search_by_index('AnFirst ASplit Lastname', record_type, sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: record.id.to_s, type: record_type }])
      end
    end

    context 'for query with no results' do
      subject(:search) { described_class.search_by_index(query, index, limit: 3000, with_total_count:) }

      let(:query) { 'preferences.notification_sound.enabled:*' }
      let(:with_total_count) { false }

      context 'on a single index' do
        let(:index) { 'User' }

        it { is_expected.to be_an(Array).and be_empty }

        context 'when with_total_count is given' do
          let(:with_total_count) { true }

          it { is_expected.to include(total_count: 0, object_metadata: be_empty) }
        end
      end

      context 'when user has a signature detection' do
        let(:user)        { create(:agent, preferences: { signature_detection: 'Hamburg' }) }
        let(:record_type) { 'Ticket'.freeze }
        let(:record)      { create(:ticket, created_by: user) }

        before do
          record.search_index_update_backend
          described_class.refresh
        end

        it 'does not find the ticket record' do
          result = described_class.search_by_index('Hamburg', record_type, sort_by: ['updated_at'], order_by: ['desc'])
          expect(result).to eq([])
        end
      end
    end

    context 'search with date that requires time zone conversion', time_zone: 'Europe/Vilnius' do
      let(:record_type) { 'Ticket'.freeze }
      let(:record)      { create(:ticket) }

      before do
        travel_to(Time.zone.parse('2019-01-02 00:33'))
        described_class.add(record_type, record)
        described_class.refresh
      end

      it 'finds record in a given timezone with a range' do
        Setting.set('timezone_default', 'UTC')
        result = described_class.search_by_index('created_at: [2019-01-01 TO 2019-01-01]', record_type)
        expect(result).to eq([{ id: record.id.to_s, type: record_type }])
      end

      it 'finds record in a far away timezone with a date' do
        Setting.set('timezone_default', 'Europe/Vilnius')
        result = described_class.search_by_index('created_at: 2019-01-02', record_type)
        expect(result).to eq([{ id: record.id.to_s, type: record_type }])
      end

      it 'finds record in UTC with date' do
        Setting.set('timezone_default', 'UTC')
        result = described_class.search_by_index('created_at: 2019-01-01', record_type)
        expect(result).to eq([{ id: record.id.to_s, type: record_type }])
      end
    end

    context 'does find integer values for ticket data', db_strategy: :reset do
      let(:record_type) { 'Ticket'.freeze }
      let(:record) { create(:ticket, inttest: '1021052349') }

      before do
        create(:object_manager_attribute_integer, name: 'inttest', data_option: {
                 'default' => 0,
                 'min'     => 0,
                 'max'     => 99_999_999,
               })
        ObjectManager::Attribute.migration_execute
        record.search_index_update_backend
        described_class.refresh
      end

      it 'finds added records by integer part' do
        result = described_class.search_by_index('102105', record_type, sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: record.id.to_s, type: record_type }])
      end

      it 'finds added records by integer' do
        result = described_class.search_by_index('1021052349', record_type, sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: record.id.to_s, type: record_type }])
      end

      it 'finds added records by quoted integer' do
        result = described_class.search_by_index('"1021052349"', record_type, sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: record.id.to_s, type: record_type }])
      end
    end

    context 'can sort by datetime fields', db_strategy: :reset do
      let(:record_type) { 'Ticket'.freeze }
      let(:record)     { create(:ticket) }
      let(:field_name) { SecureRandom.uuid }

      before do
        create(:object_manager_attribute_datetime, name: field_name)
        ObjectManager::Attribute.migration_execute
        record.search_index_update_backend
        described_class.refresh
      end

      it 'finds added records' do
        result = described_class.search_by_index(record.number, record_type, sort_by: [field_name], order_by: ['desc'])
        expect(result).to eq([{ id: record.id.to_s, type: record_type }])
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

  describe '.remove', searchindex: true do

    context 'record gets deleted' do

      let(:record_type) { 'Ticket'.freeze }
      let(:deleted_record) { create(:ticket) }

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

        let(:other_record) { create(:ticket) }

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

  describe '.selectors', searchindex: true do
    let(:initialize_object_manager_attributes) { nil }
    let(:group1)                               { create(:group) }
    let(:additional_ticket_attributes1)        { {} }
    let(:organization1)                        { create(:organization, note: 'hihi') }
    let(:agent1)                               { create(:agent, organization: organization1, groups: [group1]) }
    let(:customer1)                            { create(:customer, organization: organization1, firstname: 'special-first-name') }
    let(:ticket1) do
      attributes = {
        title:      'some-title1',
        state_id:   1,
        created_by: agent1,
        group:      group1,
      }
      ticket = create(:ticket, attributes.merge(additional_ticket_attributes1))
      ticket.tag_add('t1', 1)
      ticket
    end
    let(:ticket2) do
      ticket = create(:ticket, title: 'some_title2', state_id: 4)
      ticket.tag_add('t2', 1)
      ticket
    end
    let(:ticket3) do
      ticket = create(:ticket, title: 'some::title3', state_id: 1)
      ticket.tag_add('t1', 1)
      ticket.tag_add('t2', 1)
      ticket
    end
    let(:ticket4) { create(:ticket, title: 'phrase some-title4', state_id: 1) }
    let(:ticket5)  { create(:ticket, title: 'phrase some_title5', state_id: 1) }
    let(:ticket6)  { create(:ticket, title: 'phrase some::title6', state_id: 1) }
    let(:ticket7)  { create(:ticket, title: 'some title7', state_id: 1) }
    let(:ticket8)  { create(:ticket, title: 'sometitle', group: group1, state_id: 1, owner: agent1, customer: customer1, organization: organization1) }
    let(:article8) { create(:ticket_article, ticket: ticket8, subject: 'lorem ipsum') }

    before do
      Ticket.destroy_all # needed to remove not created tickets

      initialize_object_manager_attributes

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

    context 'when limit is used' do
      it 'finds 1 record' do
        result = described_class.selectors('Ticket', { 'ticket.created_at'=>{ 'operator' => 'till (relative)', 'value' => '30', 'range' => 'minute' } }, { limit: 1 }, { field: 'created_at' })
        expect(result[:object_ids].count).to eq(1)
      end

      it 'finds 3 records' do
        result = described_class.selectors('Ticket', { 'ticket.created_at'=>{ 'operator' => 'till (relative)', 'value' => '30', 'range' => 'minute' } }, { limit: 3 }, { field: 'created_at' })
        expect(result[:object_ids].count).to eq(3)
      end
    end

    context 'query with contains' do
      it 'finds records with till (relative)' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.created_at'=>{ 'operator' => 'till (relative)', 'value' => '30', 'range' => 'minute' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 7, object_ids: [ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      # https://github.com/zammad/zammad/issues/5105
      context 'with non-overlapping aggs_interval' do
        before do
          travel_to 18.months.from_now
          create(:ticket)
          searchindex_model_reload([Ticket])
          travel_back
        end

        it 'finds no records' do
          result = described_class.selectors('Ticket',
                                             { 'ticket.created_at'=>{ 'operator' => 'till (relative)', 'value' => '30', 'range' => 'minute' } },
                                             {},
                                             {
                                               from:     1.year.from_now,
                                               to:       2.years.from_now,
                                               interval: 'month', # year, quarter, month, week, day, hour, minute, second
                                               field:    'created_at',
                                             })

          expect(result['hits']['total']['value']).to eq(0)
        end
      end

      it 'finds records with from (relative)' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.created_at'=>{ 'operator' => 'from (relative)', 'value' => '30', 'range' => 'minute' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
      end

      it 'finds records with till (relative) including +1 hour ticket' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.created_at'=>{ 'operator' => 'till (relative)', 'value' => '120', 'range' => 'minute' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 8, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with from (relative) including -1 hour ticket' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.created_at'=>{ 'operator' => 'from (relative)', 'value' => '120', 'range' => 'minute' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 8, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with tags which contains all' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.tags'=>{ 'operator' => 'contains all', 'value' => 't1, t2' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 1, object_ids: [ticket3.id.to_s] })
      end

      it 'finds records with tags which contains one' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.tags'=>{ 'operator' => 'contains one', 'value' => 't1, t2' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 3, object_ids: [ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with tags which contains all not' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.tags'=>{ 'operator' => 'contains all not', 'value' => 't2' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 6, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with tags which contains one not' do
        result = described_class.selectors('Ticket',
                                           { 'ticket.tags'=>{ 'operator' => 'contains one not', 'value' => 't1' } },
                                           {},
                                           {
                                             field: 'created_at', # sort to verify result
                                           })
        expect(result).to eq({ count: 6, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket2.id.to_s] })
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
        expect(result).to eq({ count: 1, object_ids: [ticket8.id.to_s] })
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
        expect(result).to eq({ count: 1, object_ids: [ticket8.id.to_s] })
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
        expect(result).to eq({ count: 1, object_ids: [ticket8.id.to_s] })
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
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
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
        expect(result).to eq({ count: 1, object_ids: [ticket8.id.to_s] })
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
        expect(result).to eq({ count: 1, object_ids: [ticket8.id.to_s] })
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
        expect(result).to eq({ count: 3, object_ids: [ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s] })
      end

      it 'finds records with containing some title7' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains',
                                             'value'    => 'some title7',
                                           })
        expect(result).to eq({ count: 1, object_ids: [ticket7.id.to_s] })
      end

      it 'finds records with containing -' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains',
                                             'value'    => 'some-title1',
                                           })
        expect(result).to eq({ count: 1, object_ids: [ticket1.id.to_s] })
      end

      it 'finds records with containing _' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains',
                                             'value'    => 'some_title2',
                                           })
        expect(result).to eq({ count: 1, object_ids: [ticket2.id.to_s] })
      end

      it 'finds records with containing ::' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains',
                                             'value'    => 'some::title3',
                                           })
        expect(result).to eq({ count: 1, object_ids: [ticket3.id.to_s] })
      end

      it 'finds records with containing 4' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'contains',
                                             'value'    => 4,
                                           })
        expect(result).to eq({ count: 1, object_ids: [ticket2.id.to_s] })
      end

      it 'finds records with containing "4"' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'contains',
                                             'value'    => '4',
                                           })
        expect(result).to eq({ count: 1, object_ids: [ticket2.id.to_s] })
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
        expect(result).to eq({ count: 5, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with containing not some title7' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains not',
                                             'value'    => 'some title7',
                                           })
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with containing not -' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains not',
                                             'value'    => 'some-title1',
                                           })
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
      end

      it 'finds records with containing not _' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains not',
                                             'value'    => 'some_title2',
                                           })
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with containing not ::' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'contains not',
                                             'value'    => 'some::title3',
                                           })

        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with containing not 4' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'contains not',
                                             'value'    => 4,
                                           })

        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with containing not "4"' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'contains not',
                                             'value'    => '4',
                                           })
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket1.id.to_s] })
      end
    end

    context 'query with is' do
      it 'finds records with is phrase' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is',
                                             'value'    => 'phrase',
                                           })
        expect(result).to eq({ count: 0, object_ids: [] })
      end

      it 'finds records with is some title7' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is',
                                             'value'    => 'some title7',
                                           })
        expect(result).to eq({ count: 1, object_ids: [ticket7.id.to_s] })
      end

      it 'finds records with is -' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is',
                                             'value'    => 'some-title1',
                                           })
        expect(result).to eq({ count: 1, object_ids: [ticket1.id.to_s] })
      end

      it 'finds records with is _' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is',
                                             'value'    => 'some_title2',
                                           })
        expect(result).to eq({ count: 1, object_ids: [ticket2.id.to_s] })
      end

      it 'finds records with is ::' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is',
                                             'value'    => 'some::title3',
                                           })
        expect(result).to eq({ count: 1, object_ids: [ticket3.id.to_s] })
      end

      it 'finds records with is 4' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'is',
                                             'value'    => 4,
                                           })
        expect(result).to eq({ count: 1, object_ids: [ticket2.id.to_s] })
      end

      it 'finds records with is "4"' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'is',
                                             'value'    => '4',
                                           })

        expect(result).to eq({ count: 1, object_ids: [ticket2.id.to_s] })
      end
    end

    context 'query with is not' do
      it 'finds records with is not phrase' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is not',
                                             'value'    => 'phrase',
                                           })
        expect(result).to eq({ count: 8, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with is not some title7' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is not',
                                             'value'    => 'some title7',
                                           })
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with is not -' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is not',
                                             'value'    => 'some-title1',
                                           })
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
      end

      it 'finds records with is not _' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is not',
                                             'value'    => 'some_title2',
                                           })
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with is not ::' do
        result = described_class.selectors('Ticket',
                                           'title' => {
                                             'operator' => 'is not',
                                             'value'    => 'some::title3',
                                           })
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket2.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with is not 4' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'is not',
                                             'value'    => 4,
                                           })
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket1.id.to_s] })
      end

      it 'finds records with is not "4"' do
        result = described_class.selectors('Ticket',
                                           'state_id' => {
                                             'operator' => 'is not',
                                             'value'    => '4',
                                           })

        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket1.id.to_s] })
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

        expect(result).to eq({ count: 1, object_ids: [ticket8.id.to_s] })
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
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
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
        expect(result).to eq({ count: 1, object_ids: [ticket1.id.to_s] })
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
        expect(result).to eq({ count: 1, object_ids: [ticket1.id.to_s] })
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
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
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
        expect(result).to eq({ count: 1, object_ids: [ticket1.id.to_s] })
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
        expect(result).to eq({ count: 7, object_ids: [ticket8.id.to_s, ticket7.id.to_s, ticket6.id.to_s, ticket5.id.to_s, ticket4.id.to_s, ticket3.id.to_s, ticket2.id.to_s] })
      end
    end

    context 'with external data source field', db_strategy: :reset do
      let(:external_data_source_attribute) do
        create(:object_manager_attribute_autocompletion_ajax_external_data_source,
               name: 'external_data_source_attribute')
      end

      let(:name) { "ticket.#{external_data_source_attribute.name}" }

      let(:external_data_source_attribute_value) { 123 }
      let(:additional_ticket_attributes1) do
        {
          external_data_source_attribute.name => {
            value: external_data_source_attribute_value,
            label: 'Example'
          }
        }
      end

      let(:condition) do
        { operator: 'AND', conditions: [ {
          name:     name,
          operator: operator,
          value:    value,
        } ] }
      end

      let(:initialize_object_manager_attributes) do
        external_data_source_attribute
        ObjectManager::Attribute.migration_execute
      end

      describe "operator 'is'" do
        let(:operator) { 'is' }

        context 'with string' do
          context 'with matching string as value' do
            let(:external_data_source_attribute_value) { 'Example' }
            let(:value) do
              {
                value: 'Example',
                label: 'Example'
              }
            end

            it 'finds the ticket' do
              result = described_class.selectors('Ticket', condition, { current_user: agent1 })
              expect(result[:object_ids].count).to eq(1)
            end
          end

          context 'with non-matching string' do
            let(:value) do
              {
                value: 'Wrong',
                label: 'Wrong'
              }
            end

            it 'does not find the ticket' do
              result = described_class.selectors('Ticket', condition, { current_user: agent1 })
              expect(result[:object_ids].count).to eq(0)
            end
          end
        end

        context 'with matching integer as value' do
          let(:value) do
            {
              value: 123,
              label: 'Example'
            }
          end

          it 'finds the ticket' do
            result = described_class.selectors('Ticket', condition, { current_user: agent1 })
            expect(result[:object_ids].count).to eq(1)
          end
        end

        context 'with matching integer as value (but array style)' do
          let(:value) do
            [{
              value: 123,
              label: 'Example'
            }]
          end

          it 'finds the ticket' do
            result = described_class.selectors('Ticket', condition, { current_user: agent1 })
            expect(result[:object_ids].count).to eq(1)
          end
        end

        context 'with multiple values for matching' do
          let(:value) do
            [
              {
                value: 123,
                label: 'Example'
              },
              {
                value: 987,
                label: 'Example 2'
              }
            ]
          end

          it 'finds the ticket' do
            result = described_class.selectors('Ticket', condition, { current_user: agent1 })
            expect(result[:object_ids].count).to eq(1)
          end
        end

        context 'with matching boolean as value' do
          let(:external_data_source_attribute_value) { true }
          let(:value) do
            {
              value: true,
              label: 'Yes'
            }
          end

          it 'finds the ticket' do
            result = described_class.selectors('Ticket', condition, { current_user: agent1 })
            expect(result[:object_ids].count).to eq(1)
          end
        end
      end

      describe "operator 'is not'" do
        let(:operator) { 'is not' }

        context 'with matching integer as value' do
          let(:value) do
            {
              value: 986,
              label: 'Example'
            }
          end

          it 'find the ticket' do
            result = described_class.selectors('Ticket', condition, { current_user: agent1 })
            expect(result[:object_ids].count).to eq(8)
          end
        end
      end
    end
  end

  describe '.search_by_index_sort' do
    it 'does return a sort value' do
      expect(described_class.search_by_index_sort(index: 'Ticket', sort_by: ['title'], order_by: 'desc')).to eq([{ 'title.keyword'=>{ order: 'd' } }, '_score'])
    end

    it 'does return a sort value for fulltext searches' do
      expect(described_class.search_by_index_sort(index: 'Ticket', sort_by: ['title'], order_by: 'desc', fulltext: true)).to eq([{ 'title.keyword'=>{ order: 'd' } }, '_score'])
    end

    it 'does return a default sort value' do
      expect(described_class.search_by_index_sort(index: 'Ticket')).to eq([{ updated_at: { order: 'desc' } }, '_score'])
    end

    it 'does return a default sort value for fulltext searches' do
      expect(described_class.search_by_index_sort(index: 'Ticket', fulltext: true)).to eq(['_score'])
    end
  end

  describe 'SSL verification', searchindex: true do
    describe '.make_request' do
      def request(verify: false)
        Setting.set('es_url', 'https://127.0.0.1:9200')
        Setting.set('es_ssl_verify', verify)

        SearchIndexBackend.get('Ticket', Ticket.first.id)
      end

      it 'does verify SSL' do
        allow(UserAgent).to receive(:get_http)
        request(verify: true)
        expect(UserAgent).to have_received(:get_http).with(URI::HTTPS, hash_including(verify_ssl: true)).once
      end

      it 'does not verify SSL' do
        allow(UserAgent).to receive(:get_http)
        request
        expect(UserAgent).to have_received(:get_http).with(URI::HTTPS, hash_including(verify_ssl: false)).once
      end
    end
  end

  describe 'rake searchindex:rebuild is not working after Elasticsearch 2.4 upgrade to Elasticsearch 5.6 "Limit of total fields [1000] in index" #2297', searchindex: true do
    it 'does find store columns in search' do
      create(:ticket, preferences: { special_key: 42 })
      create(:ticket, preferences: { special_key: 43 })
      searchindex_model_reload([Ticket])
      expect(described_class.search('preferences.special_key: 42', 'Ticket').count).to eq(1)
    end
  end

  describe 'works with special characters', performs_jobs: true, searchindex: true do
    # Verify fix for Github issue #2058 - Autocomplete hangs on dot in the new user form
    it 'does searching for organization with a dot in its name' do
      organization = create(:organization, name: 'Tes.t. Org')
      perform_enqueued_jobs
      searchindex_model_reload([Organization])

      result = described_class.search 'Tes.', 'Organization'
      expect(result).to include(include(id: organization.id.to_s, type: 'Organization'))
    end

    # Search query H& should correctly match H&M
    it 'does searching for organization with & in its name' do
      organization = create(:organization, name: 'H&M')
      perform_enqueued_jobs
      searchindex_model_reload([Organization])

      result = described_class.search 'h&', 'Organization'
      expect(result).to include(include(id: organization.id.to_s, type: 'Organization'))
    end

    it 'does searching for organization with _ in its name' do
      organization = create(:organization, name: 'ABC_D')
      perform_enqueued_jobs
      searchindex_model_reload([Organization])

      result = described_class.search 'abc_', 'Organization'
      expect(result).to include(include(id: organization.id.to_s, type: 'Organization'))
    end
  end
end
