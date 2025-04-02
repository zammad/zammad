# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MicrosoftGraph, :aggregate_failures, integration: true, required_envs: %w[MICROSOFTGRAPH_REFRESH_TOKEN MICROSOFT365_CLIENT_ID MICROSOFT365_CLIENT_SECRET MICROSOFT365_CLIENT_TENANT MICROSOFT365_USER], use_vcr: true do
  let(:token) do
    {
      created_at:    1.hour.ago,
      client_id:     ENV['MICROSOFT365_CLIENT_ID'],
      client_secret: ENV['MICROSOFT365_CLIENT_SECRET'],
      client_tenant: ENV['MICROSOFT365_CLIENT_TENANT'],
      refresh_token: ENV['MICROSOFTGRAPH_REFRESH_TOKEN'],
    }.with_indifferent_access
  end

  let(:client_access_token) { ExternalCredential::MicrosoftGraph.refresh_token(token)[:access_token] }
  let(:client_mailbox)      { ENV['MICROSOFT365_USER'] }
  let(:client)              do
    VCR.configure do |c|
      c.filter_sensitive_data('<MICROSOFT365_USER>')            { ENV['MICROSOFT365_USER'] }
      c.filter_sensitive_data('<MICROSOFT365_CLIENT_ID>')       { token[:client_id] }
      c.filter_sensitive_data('<MICROSOFT365_CLIENT_SECRET>')   { token[:client_secret] }
      c.filter_sensitive_data('<MICROSOFT365_CLIENT_TENANT>')   { token[:client_tenant] }
      c.filter_sensitive_data('<MICROSOFTGRAPH_REFRESH_TOKEN>') { token[:refresh_token] }
      c.filter_sensitive_data('<MICROSOFTGRAPH_ACCESS_TOKEN>')  { client_access_token }
    end

    described_class.new(access_token: client_access_token, mailbox: client_mailbox)
  end

  # Tests #create_message_folder, #get_message_folder_details, #delete_message_folder
  describe 'folder lifecycle' do
    let(:folder_name) { "rspec-graph-client-#{SecureRandom.uuid}" }

    before do
      VCR.configure do |c|
        c.filter_sensitive_data('<FOLDER_NAME>') { folder_name }
      end
    end

    it 'tests folder lifecycle' do
      new_folder = client.create_message_folder(folder_name)

      fetched_folder = client.get_message_folder_details(new_folder['id'])

      expect(fetched_folder['displayName']).to eq(folder_name)

      client.delete_message_folder(new_folder['id'])
    end
  end

  # Tests #store_mocked_message, #get_raw_message, #get_message_basic_details, #mark_message_as_read, #message_delete, #list_messages
  describe 'message lifecycle' do
    let(:folder_name)  { "rspec-graph-client-#{SecureRandom.uuid}" }
    let(:mail_subject) { "rspec-graph-client-#{SecureRandom.uuid}" }
    let(:folder)       { client.create_message_folder(folder_name) }

    let(:message) do
      {
        subject:      mail_subject,
        body:         { content: 'Test email' },
        from:         {
          emailAddress: { address: 'from@example.com' }
        },
        toRecipients: [
          {
            emailAddress: { address: 'test@example.com' }
          }
        ],
        isRead:       false,
      }
    end

    before do
      VCR.configure do |c|
        c.filter_sensitive_data('<FOLDER_NAME>')  { folder_name }
        c.filter_sensitive_data('<MAIL_SUBJECT>') { mail_subject }
      end

      folder
    end

    after { client.delete_message_folder(folder['id']) }

    it 'tests message lifecycle' do
      new_message = client.store_mocked_message(message, folder_id: folder['id'])

      raw = client.get_raw_message(new_message['id'])
      expect(raw).to include("Subject: #{message[:subject]}")
      expect(raw).to include(message[:body][:content])

      details = client.get_message_basic_details(new_message['id'])
      expect(details).to include(size: be_positive)

      # Message is marked as unread on creation, should appear in unread messages list
      expect(client.list_messages(folder_id: folder['id'], unread_only: true))
        .to include(total_count: 1, items: include(include(id: new_message['id'])))

      client.mark_message_as_read(new_message['id'])

      # After being marked as unread, should be gone from the same list
      expect(client.list_messages(folder_id: folder['id'], unread_only: true))
        .not_to include(items: include(include(id: new_message['id'])))

      # Either way, message shows up into not-filtered-by-read-state list
      expect(client.list_messages(folder_id: folder['id']))
        .to include(items: include(include(id: new_message['id'])))

      client.delete_message(new_message['id'])
    end
  end

  describe '#get_message_folders_tree' do
    let(:top_folder_name) { "rspec-graph-client-#{SecureRandom.uuid}" }

    before do
      VCR.configure do |c|
        c.filter_sensitive_data('<TOP_FOLDER_TREE>') { top_folder_name }
      end

      top_level_folder = client.create_message_folder(top_folder_name)

      client.create_message_folder('dead-end', parent_folder_id: top_level_folder['id'])
      second_level_folder = client.create_message_folder('2nd-level', parent_folder_id: top_level_folder['id'])

      client.create_message_folder('3rd-level', parent_folder_id: second_level_folder['id'])
    end

    it 'returns tree structure of a folder' do
      expect(client.get_message_folders_tree).to include(
        include(
          displayName:  top_folder_name,
          childFolders: include(
            include(displayName: '2nd-level', childFolders: [
                      include(displayName: '3rd-level', childFolders: be_blank)
                    ]),
            include(displayName: 'dead-end', childFolders: be_blank)
          )
        )
      )
    end
  end

  # Also checks #get_message_basic_details since headers are present on real messages only
  describe '#send_mail' do
    let(:mail_subject) { "rspec-graph-client-#{SecureRandom.uuid}" }
    let(:mail) do
      {
        to:      ENV['MICROSOFT365_USER'],
        subject: mail_subject,
        body:    'Test email',
      }
    end

    before do
      VCR.configure do |c|
        # Looks like VCR cannot have repeating filter names in the same spec file
        # Thus using a slightly different string here
        c.filter_sensitive_data('<SEND_MAIL_SUBJECT>') { mail_subject }
      end
    end

    it 'sends an email' do
      client.send_message(Channel::EmailBuild.build(mail))

      # wait for email to arrive
      if !VCR.turned_on? || VCR.current_cassette.recording?
        sleep 3
      end

      mails = client.list_messages(unread_only: true, select: 'id,subject').fetch(:items)

      expect(mails).to include(
        include(subject: mail_subject)
      )

      test_email_id = mails.find { |elem| elem[:subject] == mail_subject }['id']

      details = client.get_message_basic_details(test_email_id)

      expect(details).to include(size: be_positive, headers: include(Subject: mail_subject))

      client.delete_message(test_email_id)
    end
  end

  describe '#make_paginated_request' do
    let(:page_solo) { { value: %w[A B], '@odata.count': 123 } }
    let(:page_1)    { page_solo.merge('@odata.nextLink': 'page_2', '@odata.count': 123) }
    let(:page_2)    { { value: %w[C], '@odata.nextLink': 'page_3' } }
    let(:page_3)    { { value: %w[D E] } }

    context 'when response is single-page' do
      before do
        allow(client).to receive(:make_request)
          .with('path', params: { test: true })
          .and_return(page_solo.with_indifferent_access)
      end

      it 'returns value' do
        response = client.send(:make_paginated_request, 'path', params: { test: true })

        expect(response).to eq({ total_count: 123, items: %w[A B] })
      end
    end

    context 'when response is paginated' do
      before do
        allow(client).to receive(:make_request)
          .with('path', params: { test: true })
          .and_return(page_1.with_indifferent_access)

        allow(client).to receive(:make_request)
          .with('page_2')
          .and_return(page_2.with_indifferent_access)

        allow(client).to receive(:make_request)
          .with('page_3')
          .and_return(page_3.with_indifferent_access)
      end

      context 'when follow_pagination: false' do
        it 'returns value of the first page only' do
          response = client.send(:make_paginated_request, 'path', params: { test: true }, follow_pagination: false)

          expect(response).to eq({ total_count: 123, items: %w[A B] })
        end
      end

      context 'when follow_pagination: true' do
        it 'returns concatenated values' do
          response = client.send(:make_paginated_request, 'path', params: { test: true })

          expect(response).to eq({ total_count: 123, items: %w[A B C D E] })
        end

        it 'raises error if loop limit is reached' do
          stub_const("#{described_class}::PAGINATED_MAX_LOOPS", 1)

          expect { client.send(:make_paginated_request, 'path', params: { test: true }) }
            .to raise_error(described_class::ApiError)
        end
      end
    end
  end

  describe '#headers_to_hash' do
    let(:input) do
      [
        { name: 'A', value: 'B' },
        { name: 'ABC', value: 'BBB' }
      ]
    end

    let(:output) { { 'A' => 'B', 'ABC' => 'BBB' } }

    it 'converts array-of-hashes to a simplified hash' do
      expect(client.send(:headers_to_hash, input)).to eq(output)
    end
  end
end
