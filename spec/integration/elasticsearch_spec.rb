# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Elasticsearch', searchindex: true do
  let(:assets)     { 'spec/fixtures/files/integration/elasticsearch' }
  let(:group)      { create(:group) }
  let(:agent)      { create(:agent, groups: [group]) }
  let(:customer)   { create(:customer, organization: create(:organization)) }
  let(:ticket)     { create(:ticket, owner: agent, customer: customer, group: group) }
  let(:article)    { create(:ticket_article, :inbound_phone, ticket_id: ticket.id) }
  let(:attachment) do
    create(:store,
           object:   'Ticket::Article',
           o_id:     article.id,
           data:     Rails.root.join("#{assets}/es-normal.txt").binread,
           filename: 'es-normal.txt')
  end
  let(:customers) do
    organization = create(:organization)
    [
      create(:customer, organization: organization),
      create(:customer, organization: organization),
      create(:customer),
    ]
  end
  let(:tickets) do
    tickets = [
      create(:ticket, title: 'First test ticket', customer: customers[0], owner: agent, group: group),
      create(:ticket,
             title:    'Second test ticket',
             customer: customers[1],
             owner:    agent,
             group:    group,
             state:    Ticket::State.lookup(name: 'open')),
      create(:ticket, title: 'Third test ticket', customer: customers[2]),
    ]
    tickets.each_index do |index|
      tickets[index].tag_add("Tag#{index + 1}", 1)
    end
  end
  let(:articles) do
    [
      create(:ticket_article, ticket_id: tickets[0].id).tap do |article|
        create(:store,
               object:   'Ticket::Article',
               o_id:     article.id,
               data:     Rails.root.join("#{assets}/es-normal.txt").binread,
               filename: 'es-normal.txt')
        create(:store,
               object:   'Ticket::Article',
               o_id:     article.id,
               data:     Rails.root.join("#{assets}/es-pdf1.pdf").binread,
               filename: 'es-pdf1.pdf')
        create(:store,
               object:   'Ticket::Article',
               o_id:     article.id,
               data:     Rails.root.join("#{assets}/es-box1.box").binread,
               filename: 'mail1.box')
        create(:store,
               object:   'Ticket::Article',
               o_id:     article.id,
               data:     Rails.root.join("#{assets}/es-too-big.txt").binread,
               filename: 'es-too-big.txt')
      end,
      create(:ticket_article,
             :inbound_email,
             ticket_id:    tickets[1].id,
             subject:      'some subject2 / autobahn what else?',
             body:         'some other message <b>with s<u>t</u>rong text<b>',
             content_type: 'text/html'),
      create(:ticket_article,
             :inbound_email,
             ticket_id: tickets[2].id,
             body:      'some other message 3 / kindergarden what else?')
    ]
  end

  shared_examples 'user findable' do
    describe 'and findable' do
      it 'as agent' do
        result = User.search(current_user: agent, query: query)
        expect(result).to be_present
      end

      it 'not as customer' do
        result = User.search(current_user: customer, query: query)
        expect(result).not_to be_present
      end
    end
  end

  describe 'indexes agents' do
    let(:query) { agent.lastname }

    before do
      agent
      searchindex_model_reload([User])
    end

    it 'without sensible data' do
      lookup = agent.search_index_attribute_lookup
      expect(lookup).to include('id' => agent.id).and not_include('password')
    end

    include_examples 'user findable'
  end

  describe 'indexes customers' do
    let(:query) { customer.lastname }

    before do
      customer
      searchindex_model_reload([User])
    end

    it 'without sensible data' do
      lookup = customer.search_index_attribute_lookup
      expect(lookup).to include('id' => customer.id).and not_include('password')
    end

    it 'with organization' do
      lookup = customer.search_index_attribute_lookup
      expect(lookup['organization']['id']).to eq(customer.organization.id)
    end

    include_examples 'user findable'
  end

  describe 'indexes tickets' do
    context 'without sensible data' do
      before do
        ticket
        searchindex_model_reload([Ticket])
      end

      it 'without sensible data', :aggregate_failures do
        lookup = ticket.search_index_attribute_lookup
        expect(lookup['owner']).to not_include('password')
        expect(lookup['customer']).to not_include('password')
      end
    end

    context 'with article' do
      before do
        ticket && article && attachment

        searchindex_model_reload([Ticket])
      end

      it 'with article + attachment', :aggregate_failures do
        lookup = ticket.search_index_attribute_lookup
        expect(lookup['article'][0]['id']).to eq(article.id)
        expect(lookup['article'][0]['attachment'][0]['_name']).to match(attachment.filename)
      end
    end

    describe 'and findable' do
      before do
        ticket
        searchindex_model_reload([Ticket])
      end

      it 'as agent' do
        result = Ticket.search(current_user: agent, query: ticket.title)
        expect(result).to be_present
      end

      it 'as customer' do
        result = Ticket.search(current_user: customer, query: ticket.title)
        expect(result).to be_present
      end
    end

    describe 'and searchable', :aggregate_failures do
      context 'with agent' do
        before do
          ticket
          article
          attachment

          tickets
          articles

          searchindex_model_reload([Ticket])
        end

        it 'by tag' do
          result = Ticket.search(current_user: agent, query: 'Tag1')
          expect(result[0]['id']).to eq(tickets[0].id)
          expect(result.size).to eq(1)
        end

        it 'by customer' do
          result = Ticket.search(current_user: agent, query: tickets[0].customer.email)
          expect(result[0]['id']).to eq(tickets[0].id)
          expect(result.size).to eq(1)
        end

        it 'by article subject' do
          result = Ticket.search(current_user: agent, query: articles[0].subject)
          expect(result[0]['id']).to eq(tickets[0].id)
          expect(result.size).to eq(2)
        end

        it 'by article attachment content' do
          result = Ticket.search(current_user: agent, query: '"some normal text66"')
          expect(result[0]['id']).to eq(tickets[0].id)
          expect(result.size).to eq(2)
        end

        it 'not by big attachments' do
          result = Ticket.search(current_user: agent, query: '"some too big text88"')
          expect(result).not_to be_present
        end

        it 'by article html content' do
          result = Ticket.search(current_user: agent, query: 'strong')
          expect(result[0]['id']).to eq(tickets[1].id)
          expect(result.size).to eq(1)
        end

        it 'not without permission' do
          result = Ticket.search(current_user: agent, query: 'kindergarden')
          expect(result).not_to be_present
        end

        describe 'by query filter' do
          it 'tags' do
            result = Ticket.search(current_user: agent, query: 'tags:Tag2')
            expect(result[0]['id']).to eq(tickets[1].id)
            expect(result.size).to eq(1)
          end

          it 'state.name' do
            result = Ticket.search(current_user: agent, query: 'state.name:open')
            expect(result[0]['id']).to eq(tickets[1].id)
            expect(result.size).to eq(1)
          end

          it 'article.from' do
            result = Ticket.search(current_user: agent, query: "article.from:\"#{tickets[0].articles[0].from}\"")
            expect(result[0]['id']).to eq(tickets[1].id)
            expect(result.size).to eq(2)
          end
        end

        describe 'after modification', performs_jobs: true do
          before do
            tag_item = Tag::Item.lookup(name: 'Tag1')
            Tag::Item.rename(
              id:            tag_item.id,
              name:          'Tag4711',
              updated_by_id: agent.id,
            )
            searchindex_model_reload([Ticket])
          end

          it 'tags' do
            result = Ticket.search(current_user: agent, query: 'tags:Tag4711')
            expect(result[0]['id']).to eq(tickets[0].id)
            expect(result.size).to eq(1)
          end
        end
      end

      context 'with customer' do
        before do
          tickets
          searchindex_model_reload([Ticket])
        end

        it 'by query OR clause' do
          result = Ticket.search(current_user: customers[0], query: 'First OR ticket')
          expect(result[0]['id']).to eq(tickets[1].id)
          expect(result[1]['id']).to eq(tickets[0].id)
          expect(result.size).to eq(2)
        end

        it 'not without permission by query OR clause' do
          result = Ticket.search(current_user: customers[2], query: 'First OR Second')
          expect(result).not_to be_present
        end
      end
    end
  end
end
