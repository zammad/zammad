# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Article API endpoints', type: :request do

  let(:admin) do
    create(:admin, groups: Group.all)
  end
  let!(:group) { create(:group) }

  let(:agent) do
    create(:agent, groups: Group.all)
  end
  let(:customer) do
    create(:customer)
  end

  describe 'request handling' do

    it 'does ticket create with agent and articles' do
      params = {
        title:       'a new ticket #1',
        group:       'Users',
        customer_id: customer.id,
        article:     {
          body: 'some body',
        }
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)

      params = {
        ticket_id:    json_response['id'],
        content_type: 'text/plain', # or text/html
        body:         'some body',
        type:         'note',
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      ticket = Ticket.find(json_response['ticket_id'])
      expect(ticket.articles.count).to eq(2)
      expect(ticket.articles[0].attachments.count).to eq(0)
      expect(ticket.articles[1].attachments.count).to eq(0)

      params = {
        ticket_id:    json_response['ticket_id'],
        content_type: 'text/html', # or text/html
        body:         'some body <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA
AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
9TXL0Y4OHwAAAABJRU5ErkJggg==" alt="Red dot" />',
        type:         'note',
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).not_to match(%r{some body <img src="cid:.+?})
      expect(json_response['body']).to match(%r{some body <img src="/api/v1/ticket_attachment/.+?" alt="Red dot"})
      expect(json_response['content_type']).to eq('text/html')
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      expect(ticket.articles.count).to eq(3)
      expect(ticket.articles[0].attachments.count).to eq(0)
      expect(ticket.articles[1].attachments.count).to eq(0)
      expect(ticket.articles[2].attachments.count).to eq(1)
      expect(ticket.articles[2].attachments[0]['id']).to be_truthy
      expect(ticket.articles[2].attachments[0]['filename']).to eq('image1.png')
      expect(ticket.articles[2].attachments[0]['size']).to eq('21')
      expect(ticket.articles[2].attachments[0]['preferences']['Mime-Type']).to eq('image/png')
      expect(ticket.articles[2].attachments[0]['preferences']['Content-Disposition']).to eq('inline')
      expect(ticket.articles[2].attachments[0]['preferences']['Content-ID']).to match(%r{@zammad.example.com})

      params = {
        ticket_id:    json_response['ticket_id'],
        content_type: 'text/html', # or text/html
        body:         'some body',
        type:         'note',
        attachments:  [
          { 'filename'  => 'some_file.txt',
            'data'      => 'dGVzdCAxMjM=',
            'mime-type' => 'text/plain' },
        ],
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/html')
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)

      expect(ticket.articles.count).to eq(4)
      expect(ticket.articles[0].attachments.count).to eq(0)
      expect(ticket.articles[1].attachments.count).to eq(0)
      expect(ticket.articles[2].attachments.count).to eq(1)
      expect(ticket.articles[3].attachments.count).to eq(1)

      get "/api/v1/ticket_articles/#{json_response['id']}?expand=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['attachments'].count).to eq(1)
      expect(json_response['attachments'][0]['id']).to be_truthy
      expect(json_response['attachments'][0]['filename']).to eq('some_file.txt')
      expect(json_response['attachments'][0]['size']).to eq('8')
      expect(json_response['attachments'][0]['preferences']['Mime-Type']).to eq('text/plain')

      params = {
        ticket_id:    json_response['ticket_id'],
        content_type: 'text/plain',
        body:         'some body',
        type:         'note',
        internal:     false,
        preferences:  {
          some_key1: 123,
          highlight: '123',
        },
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some body')
      expect(json_response['internal']).to be(false)
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
      expect(json_response['preferences']['some_key1']).to eq(123)
      expect(json_response['preferences']['highlight']).to eq('123')
      expect(ticket.articles.count).to eq(5)

      params = {
        body:        'some body 2',
        internal:    true,
        preferences: {
          some_key2: 'abc',
          highlight: '234',
        },
      }
      put "/api/v1/ticket_articles/#{json_response['id']}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).not_to eq('some body 2')
      expect(json_response['internal']).to be(true)
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['updated_by_id']).to eq(agent.id)
      expect(json_response['created_by_id']).to eq(agent.id)
      expect(json_response['preferences']['some_key1']).to eq(123)
      expect(json_response['preferences']['some_key2']).not_to eq('abc')
      expect(json_response['preferences']['highlight']).to eq('234')

    end

    it 'does ticket create with customer and articles' do
      params = {
        title:   'a new ticket #2',
        group:   'Users',
        article: {
          body: 'some body',
        }
      }
      authenticated_as(customer)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)

      params = {
        ticket_id:    json_response['id'],
        content_type: 'text/plain', # or text/html
        body:         'some body',
        type:         'note',
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['updated_by_id']).to eq(customer.id)
      expect(json_response['created_by_id']).to eq(customer.id)

      ticket = Ticket.find(json_response['ticket_id'])
      expect(ticket.articles.count).to eq(2)
      expect(ticket.articles[1].sender.name).to eq('Customer')
      expect(ticket.articles[0].attachments.count).to eq(0)
      expect(ticket.articles[1].attachments.count).to eq(0)

      params = {
        ticket_id:    json_response['ticket_id'],
        content_type: 'text/plain', # or text/html
        body:         'some body',
        sender:       'Agent',
        type:         'note',
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['updated_by_id']).to eq(customer.id)
      expect(json_response['created_by_id']).to eq(customer.id)

      ticket = Ticket.find(json_response['ticket_id'])
      expect(ticket.articles.count).to eq(3)
      expect(ticket.articles[2].sender.name).to eq('Customer')
      expect(ticket.articles[2].internal).to be(false)
      expect(ticket.articles[0].attachments.count).to eq(0)
      expect(ticket.articles[1].attachments.count).to eq(0)
      expect(ticket.articles[2].attachments.count).to eq(0)

      params = {
        ticket_id:    json_response['ticket_id'],
        content_type: 'text/plain', # or text/html
        body:         'some body 2',
        sender:       'Agent',
        type:         'note',
        internal:     true,
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some body 2')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['updated_by_id']).to eq(customer.id)
      expect(json_response['created_by_id']).to eq(customer.id)

      ticket = Ticket.find(json_response['ticket_id'])
      expect(ticket.articles.count).to eq(4)
      expect(ticket.articles[3].sender.name).to eq('Customer')
      expect(ticket.articles[3].internal).to be(false)
      expect(ticket.articles[0].attachments.count).to eq(0)
      expect(ticket.articles[1].attachments.count).to eq(0)
      expect(ticket.articles[2].attachments.count).to eq(0)
      expect(ticket.articles[3].attachments.count).to eq(0)

      # add internal article
      article = create(
        :ticket_article,
        ticket_id: ticket.id,
        internal:  true,
        sender:    Ticket::Article::Sender.find_by(name: 'Agent'),
        type:      Ticket::Article::Type.find_by(name: 'note'),
      )
      expect(ticket.articles.count).to eq(5)
      expect(ticket.articles[4].sender.name).to eq('Agent')
      expect(ticket.articles[4].updated_by_id).to eq(1)
      expect(ticket.articles[4].created_by_id).to eq(1)
      expect(ticket.articles[0].attachments.count).to eq(0)
      expect(ticket.articles[1].attachments.count).to eq(0)
      expect(ticket.articles[2].attachments.count).to eq(0)
      expect(ticket.articles[3].attachments.count).to eq(0)
      expect(ticket.articles[4].attachments.count).to eq(0)

      get "/api/v1/ticket_articles/#{article.id}", params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Not authorized')

      put "/api/v1/ticket_articles/#{article.id}", params: { internal: false }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Not authorized')

    end

    it 'does create phone ticket for customer and expected origin_by_id' do
      params = {
        title:       'a new ticket #1',
        group:       'Users',
        customer_id: customer.id,
        article:     {
          body:   'some body',
          sender: 'Customer',
          type:   'phone',
        }
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)
      expect(json_response['title']).to eq('a new ticket #1')

      expect(Ticket::Article.where(ticket_id: json_response['id']).count).to eq(2) # original + auto responder

      article = Ticket::Article.where(ticket_id: json_response['id']).first
      expect(article.origin_by_id).to eq(customer.id)
      expect(article.from).to eq("#{customer.firstname} #{customer.lastname} <#{customer.email}>")
    end

    it 'does create phone ticket by customer and manipulate origin_by_id' do
      params = {
        title:       'a new ticket #1',
        group:       'Users',
        customer_id: customer.id,
        article:     {
          body:         'some body',
          sender:       'Customer',
          type:         'phone',
          origin_by_id: 1,
        }
      }
      authenticated_as(customer)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a(Hash)

      expect(Ticket::Article.where(ticket_id: json_response['id']).count).to eq(1) # ony original

      article = Ticket::Article.where(ticket_id: json_response['id']).first
      expect(article.origin_by_id).to eq(customer.id)
    end

    it 'does ticket split with html - check attachments' do
      ticket = create(:ticket, group: group)
      article = create(
        :ticket_article,
        ticket_id:    ticket.id,
        type:         Ticket::Article::Type.lookup(name: 'note'),
        sender:       Ticket::Article::Sender.lookup(name: 'Customer'),
        body:         '<b>test</b> <img src="cid:15.274327094.140938@ZAMMAD.example.com"/> test <img src="cid:15.274327094.140938.3@ZAMMAD.example.com"/>',
        content_type: 'text/html',
      )
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        'content_file1_normally_should_be_an_image',
             filename:    'some_file1.jpg',
             preferences: {
               'Content-Type'        => 'image/jpeg',
               'Mime-Type'           => 'image/jpeg',
               'Content-ID'          => '15.274327094.140938@zammad.example.com',
               'Content-Disposition' => 'inline',
             })
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        'content_file2_normally_should_be_an_image',
             filename:    'some_file2.jpg',
             preferences: {
               'Content-Type'        => 'image/jpeg',
               'Mime-Type'           => 'image/jpeg',
               'Content-ID'          => '15.274327094.140938.2@zammad.example.com',
               'Content-Disposition' => 'inline',
             })
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        'content_file3_normally_should_be_an_image',
             filename:    'some_file3.jpg',
             preferences: {
               'Content-Type' => 'image/jpeg',
               'Mime-Type'    => 'image/jpeg',
               'Content-ID'   => '15.274327094.140938.3@zammad.example.com',
             })
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        'content_file4_normally_should_be_an_image',
             filename:    'some_file4.jpg',
             preferences: {
               'Content-Type' => 'image/jpeg',
               'Mime-Type'    => 'image/jpeg',
               'Content-ID'   => '15.274327094.140938.4@zammad.example.com',
             })
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        'content_file1_normally_should_be_an_pdf',
             filename:    'Rechnung_RE-2018-200.pdf',
             preferences: {
               'Content-Type'        => 'application/octet-stream; name="Rechnung_RE-2018-200.pdf"',
               'Mime-Type'           => 'application/octet-stream',
               'Content-ID'          => '8AB0BEC88984EE4EBEF643C79C8E0346@zammad.example.com',
               'Content-Description' => 'Rechnung_RE-2018-200.pdf',
               'Content-Disposition' => 'attachment',
             })

      params = {
        form_id: 'new_form_id123',
      }
      authenticated_as(agent)
      post "/api/v1/ticket_attachment_upload_clone_by_article/#{article.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['attachments']).to be_truthy
      expect(json_response['attachments'].count).to eq(3)

      post "/api/v1/ticket_attachment_upload_clone_by_article/#{article.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['attachments']).to be_truthy
      expect(json_response['attachments'].count).to eq(0)
    end

    it 'does ticket split with plain - check attachments' do
      ticket = create(
        :ticket,
        group:         group,
        updated_by_id: agent.id,
        created_by_id: agent.id,
      )
      article = create(
        :ticket_article,
        ticket_id:     ticket.id,
        type:          Ticket::Article::Type.lookup(name: 'note'),
        sender:        Ticket::Article::Sender.lookup(name: 'Customer'),
        body:          '<b>test</b> <img src="cid:15.274327094.140938@zammad.example.com"/>',
        content_type:  'text/plain',
        updated_by_id: 1,
        created_by_id: 1,
      )
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        'content_file1_normally_should_be_an_image',
             filename:    'some_file1.jpg',
             preferences: {
               'Content-Type'        => 'image/jpeg',
               'Mime-Type'           => 'image/jpeg',
               'Content-ID'          => '15.274327094.140938@zammad.example.com',
               'Content-Disposition' => 'inline',
             })
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        'content_file1_normally_should_be_an_image',
             filename:    'some_file2.jpg',
             preferences: {
               'Content-Type'        => 'image/jpeg',
               'Mime-Type'           => 'image/jpeg',
               'Content-ID'          => '15.274327094.140938.2@zammad.example.com',
               'Content-Disposition' => 'inline',
             })
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        'content_file1_normally_should_be_an_pdf',
             filename:    'Rechnung_RE-2018-200.pdf',
             preferences: {
               'Content-Type'        => 'application/octet-stream; name="Rechnung_RE-2018-200.pdf"',
               'Mime-Type'           => 'application/octet-stream',
               'Content-ID'          => '8AB0BEC88984EE4EBEF643C79C8E0346@zammad.example.com',
               'Content-Description' => 'Rechnung_RE-2018-200.pdf',
               'Content-Disposition' => 'attachment',
             })

      params = {
        form_id: 'new_form_id123',
      }
      authenticated_as(agent)
      post "/api/v1/ticket_attachment_upload_clone_by_article/#{article.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['attachments']).to be_truthy
      expect(json_response['attachments'].count).to eq(3)

      post "/api/v1/ticket_attachment_upload_clone_by_article/#{article.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['attachments']).to be_truthy
      expect(json_response['attachments'].count).to eq(0)
    end

    it 'does ticket create with mentions' do
      params = {
        title:       'a new ticket #1',
        group:       'Users',
        customer_id: customer.id,
        article:     {
          body: "some body <a data-mention-user-id=\"#{agent.id}\">agent</a>",
        }
      }
      authenticated_as(agent)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(Mention.where(mentionable: Ticket.last).count).to eq(1)
    end

    it 'does not ticket create with mentions when customer' do
      params = {
        title:       'a new ticket #1',
        group:       'Users',
        customer_id: customer.id,
        article:     {
          body: "some body <a data-mention-user-id=\"#{agent.id}\">agent</a>",
        }
      }
      authenticated_as(customer)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:internal_server_error)
      expect(Mention.count).to eq(0)
    end
  end

  describe 'DELETE /api/v1/ticket_articles/:id', authenticated_as: -> { user } do
    let(:other_agent) { create(:agent, groups: [Group.first]) }

    let(:ticket) do
      create(:ticket, group: Group.first)
    end

    let(:article_communication) do
      create(:ticket_article,
             sender_name: 'Agent', type_name: 'email', ticket: ticket,
             updated_by_id: agent.id, created_by_id: agent.id)
    end

    let(:article_note_self) do
      create(:ticket_article,
             sender_name: 'Agent', internal: true, type_name: 'note', ticket: ticket,
             updated_by_id: user.id, created_by_id: user.id)
    end

    let(:article_note_other) do
      create(:ticket_article,
             sender_name: 'Agent', internal: true, type_name: 'note', ticket: ticket,
             updated_by_id: other_agent.id, created_by_id: other_agent.id)
    end

    let(:article_note_customer) do
      create(:ticket_article,
             sender_name: 'Customer', internal: false, type_name: 'note', ticket: ticket,
             updated_by_id: customer.id, created_by_id: customer.id)
    end

    let(:article_note_communication_self) do
      create(:ticket_article_type, name: 'note_communication', communication: true)

      create(:ticket_article,
             sender_name: 'Agent', internal: true, type_name: 'note_communication', ticket: ticket,
             updated_by_id: user.id, created_by_id: user.id)
    end

    let(:article_note_communication_other) do
      create(:ticket_article_type, name: 'note_communication', communication: true)

      create(:ticket_article,
             sender_name: 'Agent', internal: true, type_name: 'note_communication', ticket: ticket,
             updated_by_id: other_agent.id, created_by_id: other_agent.id)
    end

    def delete_article_via_rest(article)
      delete "/api/v1/ticket_articles/#{article.id}", params: {}, as: :json
    end

    shared_examples 'succeeds' do
      it 'succeeds' do
        expect { delete_article_via_rest(article) }.to change { Ticket::Article.exists?(id: article.id) }
      end
    end

    shared_examples 'fails' do
      it 'fails' do
        expect { delete_article_via_rest(article) }.not_to change { Ticket::Article.exists?(id: article.id) }
      end
    end

    shared_examples 'deleting' do |item:, now:, later:, much_later:|
      context "deleting #{item}" do
        let(:article) { send(item) }

        include_examples now ? 'succeeds' : 'fails'

        context '8 minutes later' do
          before { article && travel(8.minutes) }

          include_examples later ? 'succeeds' : 'fails'
        end

        context '11 minutes later' do
          before { article && travel(11.minutes) }

          include_examples much_later ? 'succeeds' : 'fails'
        end
      end
    end

    context 'as admin' do
      let(:user) { admin }

      include_examples 'deleting',
                       item: 'article_communication',
                       now: false, later: false, much_later: false

      include_examples 'deleting',
                       item: 'article_note_self',
                       now: true, later: true, much_later: false

      include_examples 'deleting',
                       item: 'article_note_other',
                       now: false, later: false, much_later: false

      include_examples 'deleting',
                       item: 'article_note_customer',
                       now: false, later: false, much_later: false

      include_examples 'deleting',
                       item: 'article_note_communication_self',
                       now: true, later: true, much_later: false

      include_examples 'deleting',
                       item: 'article_note_communication_other',
                       now: false, later: false, much_later: false
    end

    context 'as agent' do
      let(:user) { agent }

      include_examples 'deleting',
                       item: 'article_communication',
                       now: false, later: false, much_later: false

      include_examples 'deleting',
                       item: 'article_note_self',
                       now: true, later: true, much_later: false

      include_examples 'deleting',
                       item: 'article_note_other',
                       now: false, later: false, much_later: false

      include_examples 'deleting',
                       item: 'article_note_customer',
                       now: false, later: false, much_later: false

      include_examples 'deleting',
                       item: 'article_note_communication_self',
                       now: true, later: true, much_later: false

      include_examples 'deleting',
                       item: 'article_note_communication_other',
                       now: false, later: false, much_later: false
    end

    context 'as customer' do
      let(:user) { customer }

      include_examples 'deleting',
                       item: 'article_communication',
                       now: false, later: false, much_later: false

      include_examples 'deleting',
                       item: 'article_note_other',
                       now: false, later: false, much_later: false

      include_examples 'deleting',
                       item: 'article_note_customer',
                       now: false, later: false, much_later: false

      include_examples 'deleting',
                       item: 'article_note_communication_self',
                       now: false, later: false, much_later: false

      include_examples 'deleting',
                       item: 'article_note_communication_other',
                       now: false, later: false, much_later: false

    end

    context 'with custom timeframe' do
      before { Setting.set 'ui_ticket_zoom_article_delete_timeframe', 6000 }

      let(:article) { article_note_self }

      context 'as admin' do
        let(:user) { admin }

        context 'deleting before timeframe' do
          before { article && travel(5000.seconds) }

          include_examples 'succeeds'
        end

        context 'deleting after timeframe' do
          before { article && travel(8000.seconds) }

          include_examples 'fails'
        end
      end

      context 'as agent' do
        let(:user) { agent }

        context 'deleting before timeframe' do
          before { article && travel(5000.seconds) }

          include_examples 'succeeds'
        end

        context 'deleting after timeframe' do
          before { article && travel(8000.seconds) }

          include_examples 'fails'
        end
      end
    end

    context 'with timeframe as 0' do
      before { Setting.set 'ui_ticket_zoom_article_delete_timeframe', 0 }

      let(:article) { article_note_self }

      context 'as agent' do
        let(:user) { agent }

        context 'deleting long after' do
          before { article && travel(99.days) }

          include_examples 'succeeds'
        end
      end
    end
  end
end
