# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/report_examples'

RSpec.describe Report::TicketGenericTime, searchindex: true do
  include_examples 'with report examples'

  describe '.aggs' do
    it 'gets monthly aggregated results by created_at' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        interval:    'month', # year, quarter, month, week, day, hour, minute, second
        selector:    {}, # ticket selector to get only a collection of tickets
        params:      { field: 'created_at' },
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 1, 0]
    end

    it 'gets monthly aggregated results by created_at not merged' do
      result = described_class.aggs(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        interval:    'month', # year, quarter, month, week, day, hour, minute, second
        selector:    {
          'state' => {
            'operator' => 'is not',
            'value'    => 'merged'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 1, 0]
    end

    context 'when report profile has a ticket tag condition' do
      shared_examples 'getting the correct aggregated results' do
        it { expect(result).to eq expected_result }
      end

      # With tag1
      let(:ticket_1) do
        travel_to DateTime.new 2015, 1, 28, 9, 30
        ticket = create(:ticket,
                        group:    group_2,
                        customer: customer)

        ticket.tag_add('tag1', 1)
        travel_back
        ticket
      end

      # With tag2
      let(:ticket_2) do
        travel_to DateTime.new 2015, 2, 28, 9, 30
        ticket = create(:ticket,
                        group:    group_1,
                        customer: customer)

        ticket.tag_add('tag2', 1)
        travel_back
        ticket
      end

      # Without tag1 or tag2, but article with tag1
      let(:ticket_3) do
        travel_to DateTime.new 2015, 3, 28, 9, 30
        ticket = create(:ticket,
                        group:    group_1,
                        customer: customer)
        create(:ticket_article, ticket: ticket, body: 'tag1')
        travel_back
        ticket
      end

      # Without tag1 or tag2, but article with tag2
      let(:ticket_4) do
        travel_to DateTime.new 2015, 4, 28, 9, 30
        ticket = create(:ticket,
                        group:    group_1,
                        customer: customer)
        create(:ticket_article, ticket: ticket, body: 'tag2')
        travel_back
        ticket
      end

      # With tag1 and tag2
      let(:ticket_5) do
        travel_to DateTime.new 2015, 5, 28, 9, 30
        ticket = create(:ticket,
                        group:    group_1,
                        customer: customer)
        create(:ticket_article, ticket: ticket)
        ticket.tag_add('tag1', 1)
        ticket.tag_add('tag2', 1)
        travel_back
        ticket
      end

      # With tag1 and tag2, with article body tag1
      let(:ticket_6) do
        travel_to DateTime.new 2015, 6, 28, 9, 30
        ticket = create(:ticket,
                        group:    group_1,
                        customer: customer)
        create(:ticket_article, ticket: ticket, body: 'tag1')
        ticket.tag_add('tag1', 1)
        ticket.tag_add('tag2', 1)
        travel_back
        ticket
      end

      # With tag1 and tag2, with article body tag2
      let(:ticket_7) do
        travel_to DateTime.new 2015, 7, 28, 9, 30
        ticket = create(:ticket,
                        group:    group_1,
                        customer: customer)
        create(:ticket_article, ticket: ticket, body: 'tag1')
        ticket.tag_add('tag1', 1)
        ticket.tag_add('tag2', 1)
        travel_back
        ticket
      end

      # With tag1 and tag2, with article body tag1 and tag2
      let(:ticket_8) do
        travel_to DateTime.new 2015, 8, 28, 9, 30
        ticket = create(:ticket,
                        group:    group_1,
                        customer: customer)
        create(:ticket_article, ticket: ticket, body: 'tag1')
        create(:ticket_article, ticket: ticket, body: 'tag2')
        ticket.tag_add('tag1', 1)
        ticket.tag_add('tag2', 1)
        travel_back
        ticket
      end

      # Without tag1 or tag2, and without article with tag1 or tag2
      let(:ticket_9) do
        travel_to DateTime.new 2015, 4, 28, 9, 30
        ticket = create(:ticket,
                        group:    group_1,
                        customer: customer)
        travel_back
        ticket
      end

      let(:result) do
        described_class.aggs(
          range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
          range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
          interval:    'month',
          selector:    selector,
          params:      { field: 'created_at' },
        )
      end

      context 'with contains all' do
        let(:selector) do
          {
            'ticket.tags' => {
              'operator' => 'contains all',
              'value'    => 'tag1, tag2'
            }
          }
        end

        let(:expected_result) { [0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0] }

        it_behaves_like 'getting the correct aggregated results'
      end

      context 'with contains one not' do
        let(:selector) do
          {
            'ticket.tags' => {
              'operator' => 'contains one not',
              'value'    => 'tag1, tag2'
            }
          }
        end

        let(:expected_result) { [0, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0] }

        it_behaves_like 'getting the correct aggregated results'
      end

      context 'with contains one' do
        let(:selector) do
          {
            'ticket.tags' => {
              'operator' => 'contains one',
              'value'    => 'tag1, tag2'
            }
          }
        end

        let(:expected_result) { [1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0] }

        it_behaves_like 'getting the correct aggregated results'
      end

      context 'with contains all not' do
        let(:selector) do
          {
            'ticket.tags' => {
              'operator' => 'contains all not',
              'value'    => 'tag1, tag2'
            }
          }
        end

        let(:expected_result) { [1, 1, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0] }

        it_behaves_like 'getting the correct aggregated results'
      end
    end
  end

  describe '.items' do
    it 'gets items in year range by created_at' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {}, # ticket selector to get only a collection of tickets
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_7, ticket_6, ticket_5, ticket_4, ticket_3, ticket_2, ticket_1
    end

    it 'gets items in year range by created_at not merged' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'state' => {
            'operator' => 'is not',
            'value'    => 'merged'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_7, ticket_6, ticket_5, ticket_4, ticket_3, ticket_2, ticket_1
    end

    it 'gets items in year range by created_at before oct 31st' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'created_at' => {
            'operator' => 'before (absolute)',
            'value'    => '2015-10-31T00:00:00Z'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_5, ticket_4, ticket_3, ticket_2, ticket_1
    end

    it 'gets items in year range by created_at after oct 31st' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'created_at' => {
            'operator' => 'after (absolute)',
            'value'    => '2015-10-31T00:00:00Z'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_7, ticket_6
    end

    it 'gets items in 1 day from now' do
      result = described_class.items(
        range_start: 1.year.ago.beginning_of_year,
        range_end:   1.year.from_now.at_end_of_year,
        selector:    {
          'created_at' => {
            'operator' => 'after (relative)',
            'range'    => 'day',
            'value'    => '1'
          }
        }, # ticket selector to get only a collection of tickets
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_after_72h
    end

    it 'gets items in 1 month from now' do
      result = described_class.items(
        range_start: 1.year.ago.beginning_of_year,
        range_end:   1.year.from_now.at_end_of_year,
        selector:    {
          'created_at' => {
            'operator' => 'after (relative)',
            'range'    => 'month',
            'value'    => '1'
          }
        }, # ticket selector to get only a collection of tickets
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets []
    end

    it 'gets items in 1 month ago' do
      result = described_class.items(
        range_start: 1.year.ago.beginning_of_year,
        range_end:   1.year.from_now.at_end_of_year,
        selector:    {
          'created_at' => {
            'operator' => 'before (relative)',
            'range'    => 'month',
            'value'    => '1'
          }
        }, # ticket selector to get only a collection of tickets
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_before_40d
    end

    it 'gets items in 5 months ago' do
      result = described_class.items(
        range_start: 1.year.ago.beginning_of_year,
        range_end:   1.year.from_now.at_end_of_year,
        selector:    {
          'created_at' => {
            'operator' => 'before (relative)',
            'range'    => 'month',
            'value'    => '5'
          }
        }, # ticket selector to get only a collection of tickets
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets []
    end

    it 'gets items with aaa+bbb' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'tags' => {
            'operator' => 'contains all',
            'value'    => 'aaa, bbb'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_1
    end

    it 'gets items with not aaa+bbb' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'tags' => {
            'operator' => 'contains all not',
            'value'    => 'aaa, bbb'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_7, ticket_6, ticket_5, ticket_4, ticket_3, ticket_2
    end

    it 'gets items with aaa' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'tags' => {
            'operator' => 'contains all',
            'value'    => 'aaa'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_2, ticket_1
    end

    it 'gets items with not aaa' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'tags' => {
            'operator' => 'contains all not',
            'value'    => 'aaa'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_7, ticket_6, ticket_5, ticket_4, ticket_3
    end

    it 'gets items with one not aaa' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'tags' => {
            'operator' => 'contains one not',
            'value'    => 'aaa'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_7, ticket_6, ticket_5, ticket_4, ticket_3
    end

    it 'gets items with one not aaa+bbb' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'tags' => {
            'operator' => 'contains one not',
            'value'    => 'aaa, bbb'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_7, ticket_6, ticket_4, ticket_3
    end

    it 'gets items with one aaa' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'tags' => {
            'operator' => 'contains one',
            'value'    => 'aaa'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_2, ticket_1
    end

    it 'gets items with one aaa+bbb' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'tags' => {
            'operator' => 'contains one',
            'value'    => 'aaa, bbb'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_5, ticket_2, ticket_1
    end

    it 'gets items with test' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'title' => {
            'operator' => 'contains',
            'value'    => 'Test'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets ticket_7, ticket_6, ticket_5, ticket_4, ticket_3, ticket_2, ticket_1
    end

    it 'gets items with not test' do
      result = described_class.items(
        range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
        range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
        selector:    {
          'title' => {
            'operator' => 'contains not',
            'value'    => 'Test'
          }
        },
        params:      { field: 'created_at' },
      )

      expect(result).to match_tickets []
    end

    # Regression test for issue #2246 - Records in Reporting not updated when single ActiveRecord can not be found
    it 'correctly handles missing tickets', searchindex: false do
      class_double(SearchIndexBackend, selectors: { ticket_ids: [-1] }, drop_index: nil, drop_pipeline: nil).as_stubbed_const

      expect do
        described_class.items(
          range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
          range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
          selector:    {}, # ticket selector to get only a collection of tickets
          params:      { field: 'created_at' },
        )
      end.not_to raise_error
    end
  end

  context 'when additional attribute exists', db_strategy: :reset do
    before do
      ObjectManager::Attribute.add(
        object:        'Ticket',
        name:          'test_category',
        display:       'Test 1',
        data_type:     'tree_select',
        data_option:   {
          maxlength: 200,
          null:      false,
          default:   '',
          options:   [
            { 'name' => 'aa', 'value' => 'aa', 'children' => [{ 'name' => 'aa', 'value' => 'aa::aa' }, { 'name' => 'bb', 'value' => 'aa::bb' }, { 'name' => 'cc', 'value' => 'aa::cc' }] },
            { 'name' => 'bb', 'value' => 'bb', 'children' => [{ 'name' => 'aa', 'value' => 'bb::aa' }, { 'name' => 'bb', 'value' => 'bb::bb' }, { 'name' => 'cc', 'value' => 'bb::cc' }] },
            { 'name' => 'cc', 'value' => 'cc', 'children' => [{ 'name' => 'aa', 'value' => 'cc::aa' }, { 'name' => 'bb', 'value' => 'cc::bb' }, { 'name' => 'cc', 'value' => 'cc::cc' }] },
          ]
        },
        active:        true,
        screens:       {},
        position:      20,
        created_by_id: 1,
        updated_by_id: 1,
        editable:      false,
        to_migrate:    false,
      )
      ObjectManager::Attribute.migration_execute

      ticket_with_category

      searchindex_model_reload([Ticket])
    end

    let(:ticket_with_category) do
      travel_to DateTime.new 2015, 10, 28, 9, 30
      ticket = create(:ticket,
                      group:         group_2,
                      customer:      customer,
                      test_category: 'cc::bb',
                      state_name:    'new',
                      priority_name: '2 normal')

      ticket.tag_add('aaa', 1)
      ticket.tag_add('bbb', 1)
      create(:ticket_article,
             :inbound_email,
             ticket: ticket)

      travel 5.hours

      ticket.update! group: group_1

      travel_back
      ticket
    end

    describe '.items' do
      it 'gets items with test_category cc:bb' do
        result = described_class.items(
          range_start: Time.zone.parse('2015-01-01T00:00:00Z'),
          range_end:   Time.zone.parse('2015-12-31T23:59:59Z'),
          selector:    {
            'test_category' => {
              'operator' => 'is',
              'value'    => 'cc::bb'
            },
          },
          params:      { field: 'created_at' },
        )

        expect(result).to match_tickets ticket_with_category
      end
    end
  end
end
