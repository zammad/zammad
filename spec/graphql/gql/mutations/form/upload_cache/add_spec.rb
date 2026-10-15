# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Behavior is covered by spec/services/service/upload_cache/add_spec.rb.
RSpec.describe Gql::Mutations::Form::UploadCache::Add, type: :graphql do

  context 'when uploading files for a form', authenticated_as: :agent do
    let(:agent) { create(:agent) }
    let(:query) do
      <<~QUERY
        mutation formUploadCacheAdd($formId: FormId!, $files: [UploadCacheFileInput!]!) {
          formUploadCacheAdd(formId: $formId, files: $files) {
            uploadedFiles {
              id
              name
              type
            }
          }
        }
      QUERY
    end
    let(:form_id)      { SecureRandom.uuid }
    let(:file_name)    { 'my_testfile.pdf' }
    let(:file_type)    { 'application/pdf' }
    let(:file_content) { 'some test content' }
    let(:variables) do
      {
        formId: form_id,
        files:  [
          {
            name:    file_name,
            type:    file_type,
            content: Base64.strict_encode64(file_content),
          }
        ]
      }
    end

    let(:expected_response) do
      [{
        'id'   => gql.id(UploadCache.new(form_id).attachments.first),
        'name' => file_name,
        'type' => file_type,
      }]
    end

    before do
      gql.execute(query, variables: variables)
    end

    it 'creates Store entry' do
      expect(gql.result.data[:uploadedFiles]).to eq(expected_response)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  context 'when adding to another users populated cache', authenticated_as: :agent do
    let(:agent)         { create(:agent) }
    let(:other_agent)   { create(:agent) }
    let(:form_id)       { SecureRandom.uuid }
    let(:file_name)     { 'intruder.txt' }
    let(:file_type)     { 'text/plain' }
    let(:file_content)  { 'Intruder content' }
    let(:query) do
      <<~QUERY
        mutation formUploadCacheAdd($formId: FormId!, $files: [UploadCacheFileInput!]!) {
          formUploadCacheAdd(formId: $formId, files: $files) {
            uploadedFiles {
              id
              name
              type
            }
          }
        }
      QUERY
    end
    let(:variables) do
      {
        formId: form_id,
        files:  [{
          name:    file_name,
          type:    file_type,
          content: Base64.strict_encode64(file_content),
        }]
      }
    end

    before do
      UploadCache.new(form_id).add(
        filename:      'other_agent.txt',
        data:          'Other agent data',
        preferences:   { 'Content-Type' => 'text/plain' },
        created_by_id: other_agent.id,
      )
      gql.execute(query, variables: variables)
    end

    it 'forbids adding to another users cache' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when copying an attachment', authenticated_as: :agent do
    let(:agent)      { create(:agent, groups: [article.ticket.group]) }
    let(:article)    { create(:ticket_article, :inbound_email) }
    let(:attachment) { create(:store, :image, object: 'Ticket::Article', o_id: article.id) }
    let(:form_id)    { SecureRandom.uuid }
    let(:files)      { [{ attachmentId: gql.id(attachment), inline: true }] }
    let(:query) do
      <<~QUERY
        mutation formUploadCacheAdd($formId: FormId!, $files: [UploadCacheFileInput!]!) {
          formUploadCacheAdd(formId: $formId, files: $files) {
            uploadedFiles {
              id
              name
              type
            }
          }
        }
      QUERY
    end

    before do
      gql.execute(query, variables: { formId: form_id, files: })
    end

    it 'returns the copied file' do
      expect(gql.result.data[:uploadedFiles]).to eq([{
                                                      'id'   => gql.id(UploadCache.new(form_id).attachments.first),
                                                      'name' => attachment.filename,
                                                      'type' => 'image/png',
                                                    }])
    end

    context 'when the attachment is not accessible' do
      let(:agent) { create(:agent) }

      it 'responds with an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when neither content nor attachment is given' do
      let(:files) { [{ name: 'empty.txt' }] }

      it 'responds with an error' do
        expect(gql.result.error_message).to include('exactly one')
      end
    end

    context 'when both content and attachment are given' do
      let(:files) { [{ attachmentId: gql.id(attachment), content: Base64.strict_encode64('content') }] }

      it 'responds with an error' do
        expect(gql.result.error_message).to include('exactly one')
      end
    end
  end
end
