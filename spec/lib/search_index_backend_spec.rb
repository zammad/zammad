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
    subject(:search) { described_class.search(query, index, limit: 3000) }

    context 'for query with no results' do
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
        expect(queries.map(&described_class.method(:append_wildcard_to_simple_query)))
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
        expect(queries.map(&described_class.method(:append_wildcard_to_simple_query)))
          .to eq(queries)
      end
    end
  end

  describe '.remove' do
    context 'ticket' do
      it 'from index after ticket delete' do

        skip('No ES configured') if !described_class.enabled?

        ticket = create :ticket
        described_class.add('Ticket', ticket)

        # give es time to rebuild index
        sleep 2
        result = described_class.search(ticket.number, 'Ticket', sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([{ id: ticket.id.to_s, type: 'Ticket' }])

        described_class.remove('Ticket', ticket.id)
        # give es time to rebuild index
        sleep 2

        result = described_class.search(ticket.number, 'Ticket', sort_by: ['updated_at'], order_by: ['desc'])
        expect(result).to eq([])
      end
    end
  end
end
