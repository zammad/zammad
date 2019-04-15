require 'rails_helper'

RSpec.describe 'Ticket Article', type: :request do

  let(:admin_user) do
    create(:admin_user)
  end
  let!(:group) { create(:group) }

  let(:agent_user) do
    create(:agent_user, groups: Group.all)
  end
  let(:customer_user) do
    create(:customer_user)
  end

  describe 'request handling' do

    it 'does ticket create with agent and articles' do
      params = {
        title:       'a new ticket #1',
        group:       'Users',
        customer_id: customer_user.id,
        article:     {
          body: 'some body',
        }
      }
      authenticated_as(agent_user)
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
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['updated_by_id']).to eq(agent_user.id)
      expect(json_response['created_by_id']).to eq(agent_user.id)

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
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).not_to match(/some body <img src="cid:.+?/)
      expect(json_response['body']).to match(%r{some body <img src="/api/v1/ticket_attachment/.+?" alt="Red dot"})
      expect(json_response['content_type']).to eq('text/html')
      expect(json_response['updated_by_id']).to eq(agent_user.id)
      expect(json_response['created_by_id']).to eq(agent_user.id)

      expect(ticket.articles.count).to eq(3)
      expect(ticket.articles[0].attachments.count).to eq(0)
      expect(ticket.articles[1].attachments.count).to eq(0)
      expect(ticket.articles[2].attachments.count).to eq(1)
      expect(ticket.articles[2].attachments[0]['id']).to be_truthy
      expect(ticket.articles[2].attachments[0]['filename']).to eq('image1.png')
      expect(ticket.articles[2].attachments[0]['size']).to eq('21')
      expect(ticket.articles[2].attachments[0]['preferences']['Mime-Type']).to eq('image/png')
      expect(ticket.articles[2].attachments[0]['preferences']['Content-Disposition']).to eq('inline')
      expect(ticket.articles[2].attachments[0]['preferences']['Content-ID']).to match(/@zammad.example.com/)

      params = {
        ticket_id:    json_response['ticket_id'],
        content_type: 'text/html', # or text/html
        body:         'some body',
        type:         'note',
        attachments:  [
          'filename'  => 'some_file.txt',
          'data'      => 'dGVzdCAxMjM=',
          'mime-type' => 'text/plain',
        ],
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/html')
      expect(json_response['updated_by_id']).to eq(agent_user.id)
      expect(json_response['created_by_id']).to eq(agent_user.id)

      expect(ticket.articles.count).to eq(4)
      expect(ticket.articles[0].attachments.count).to eq(0)
      expect(ticket.articles[1].attachments.count).to eq(0)
      expect(ticket.articles[2].attachments.count).to eq(1)
      expect(ticket.articles[3].attachments.count).to eq(1)

      get "/api/v1/ticket_articles/#{json_response['id']}?expand=true", params: {}, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
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
        preferences:  {
          some_key1: 123,
        },
      }
      post '/api/v1/ticket_articles', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['updated_by_id']).to eq(agent_user.id)
      expect(json_response['created_by_id']).to eq(agent_user.id)
      expect(json_response['preferences']['some_key1']).to eq(123)
      expect(ticket.articles.count).to eq(5)

      params = {
        body:        'some body 2',
        preferences: {
          some_key2: 'abc',
        },
      }
      put "/api/v1/ticket_articles/#{json_response['id']}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some body 2')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['updated_by_id']).to eq(agent_user.id)
      expect(json_response['created_by_id']).to eq(agent_user.id)
      expect(json_response['preferences']['some_key1']).to eq(123)
      expect(json_response['preferences']['some_key2']).to eq('abc')

    end

    it 'does ticket create with customer and articles' do
      params = {
        title:   'a new ticket #2',
        group:   'Users',
        article: {
          body: 'some body',
        }
      }
      authenticated_as(customer_user)
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
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['updated_by_id']).to eq(customer_user.id)
      expect(json_response['created_by_id']).to eq(customer_user.id)

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
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some body')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['updated_by_id']).to eq(customer_user.id)
      expect(json_response['created_by_id']).to eq(customer_user.id)

      ticket = Ticket.find(json_response['ticket_id'])
      expect(ticket.articles.count).to eq(3)
      expect(ticket.articles[2].sender.name).to eq('Customer')
      expect(ticket.articles[2].internal).to eq(false)
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
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['subject']).to be_nil
      expect(json_response['body']).to eq('some body 2')
      expect(json_response['content_type']).to eq('text/plain')
      expect(json_response['updated_by_id']).to eq(customer_user.id)
      expect(json_response['created_by_id']).to eq(customer_user.id)

      ticket = Ticket.find(json_response['ticket_id'])
      expect(ticket.articles.count).to eq(4)
      expect(ticket.articles[3].sender.name).to eq('Customer')
      expect(ticket.articles[3].internal).to eq(false)
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
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized')

      put "/api/v1/ticket_articles/#{article.id}", params: { internal: false }, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized')

    end

    it 'does create phone ticket for customer and expected origin_by_id' do
      params = {
        title:       'a new ticket #1',
        group:       'Users',
        customer_id: customer_user.id,
        article:     {
          body:   'some body',
          sender: 'Customer',
          type:   'phone',
        }
      }
      authenticated_as(agent_user)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['title']).to eq('a new ticket #1')

      expect(Ticket::Article.where(ticket_id: json_response['id']).count).to eq(2) # original + auto responder

      article = Ticket::Article.where(ticket_id: json_response['id']).first
      expect(article.origin_by_id).to eq(customer_user.id)
      expect(article.from).to eq("#{customer_user.firstname} #{customer_user.lastname} <#{customer_user.email}>")
    end

    it 'does create phone ticket by customer and manipulate origin_by_id' do
      params = {
        title:       'a new ticket #1',
        group:       'Users',
        customer_id: customer_user.id,
        article:     {
          body:         'some body',
          sender:       'Customer',
          type:         'phone',
          origin_by_id: 1,
        }
      }
      authenticated_as(customer_user)
      post '/api/v1/tickets', params: params, as: :json
      expect(response).to have_http_status(:created)
      expect(json_response).to be_a_kind_of(Hash)

      expect(Ticket::Article.where(ticket_id: json_response['id']).count).to eq(1) # ony original

      article = Ticket::Article.where(ticket_id: json_response['id']).first
      expect(article.origin_by_id).to eq(customer_user.id)
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
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file1_normally_should_be_an_image',
        filename:      'some_file1.jpg',
        preferences:   {
          'Content-Type'        => 'image/jpeg',
          'Mime-Type'           => 'image/jpeg',
          'Content-ID'          => '15.274327094.140938@zammad.example.com',
          'Content-Disposition' => 'inline',
        },
        created_by_id: 1,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file2_normally_should_be_an_image',
        filename:      'some_file2.jpg',
        preferences:   {
          'Content-Type'        => 'image/jpeg',
          'Mime-Type'           => 'image/jpeg',
          'Content-ID'          => '15.274327094.140938.2@zammad.example.com',
          'Content-Disposition' => 'inline',
        },
        created_by_id: 1,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file3_normally_should_be_an_image',
        filename:      'some_file3.jpg',
        preferences:   {
          'Content-Type' => 'image/jpeg',
          'Mime-Type'    => 'image/jpeg',
          'Content-ID'   => '15.274327094.140938.3@zammad.example.com',
        },
        created_by_id: 1,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file4_normally_should_be_an_image',
        filename:      'some_file4.jpg',
        preferences:   {
          'Content-Type' => 'image/jpeg',
          'Mime-Type'    => 'image/jpeg',
          'Content-ID'   => '15.274327094.140938.4@zammad.example.com',
        },
        created_by_id: 1,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file1_normally_should_be_an_pdf',
        filename:      'Rechnung_RE-2018-200.pdf',
        preferences:   {
          'Content-Type'        => 'application/octet-stream; name="Rechnung_RE-2018-200.pdf"',
          'Mime-Type'           => 'application/octet-stream',
          'Content-ID'          => '8AB0BEC88984EE4EBEF643C79C8E0346@zammad.example.com',
          'Content-Description' => 'Rechnung_RE-2018-200.pdf',
          'Content-Disposition' => 'attachment',
        },
        created_by_id: 1,
      )

      params = {
        form_id: 'new_form_id123',
      }
      authenticated_as(agent_user)
      post "/api/v1/ticket_attachment_upload_clone_by_article/#{article.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['attachments']).to be_truthy
      expect(json_response['attachments'].count).to eq(3)

      post "/api/v1/ticket_attachment_upload_clone_by_article/#{article.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['attachments']).to be_truthy
      expect(json_response['attachments'].count).to eq(0)
    end

    it 'does ticket split with plain - check attachments' do
      ticket = create(
        :ticket,
        group:         group,
        updated_by_id: agent_user.id,
        created_by_id: agent_user.id,
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
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file1_normally_should_be_an_image',
        filename:      'some_file1.jpg',
        preferences:   {
          'Content-Type'        => 'image/jpeg',
          'Mime-Type'           => 'image/jpeg',
          'Content-ID'          => '15.274327094.140938@zammad.example.com',
          'Content-Disposition' => 'inline',
        },
        created_by_id: 1,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file1_normally_should_be_an_image',
        filename:      'some_file2.jpg',
        preferences:   {
          'Content-Type'        => 'image/jpeg',
          'Mime-Type'           => 'image/jpeg',
          'Content-ID'          => '15.274327094.140938.2@zammad.example.com',
          'Content-Disposition' => 'inline',
        },
        created_by_id: 1,
      )
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'content_file1_normally_should_be_an_pdf',
        filename:      'Rechnung_RE-2018-200.pdf',
        preferences:   {
          'Content-Type'        => 'application/octet-stream; name="Rechnung_RE-2018-200.pdf"',
          'Mime-Type'           => 'application/octet-stream',
          'Content-ID'          => '8AB0BEC88984EE4EBEF643C79C8E0346@zammad.example.com',
          'Content-Description' => 'Rechnung_RE-2018-200.pdf',
          'Content-Disposition' => 'attachment',
        },
        created_by_id: 1,
      )

      params = {
        form_id: 'new_form_id123',
      }
      authenticated_as(agent_user)
      post "/api/v1/ticket_attachment_upload_clone_by_article/#{article.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['attachments']).to be_truthy
      expect(json_response['attachments'].count).to eq(3)

      post "/api/v1/ticket_attachment_upload_clone_by_article/#{article.id}", params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['attachments']).to be_truthy
      expect(json_response['attachments'].count).to eq(0)
    end
  end
end
