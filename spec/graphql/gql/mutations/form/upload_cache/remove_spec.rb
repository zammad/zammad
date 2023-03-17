# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Form::UploadCache::Remove, type: :graphql do

  context 'when uploading files for a form', authenticated_as: :agent do
    let(:agent)             { create(:agent) }
    let(:query)             do
      <<~QUERY
        mutation formUploadCacheRemove($formId: FormId!, $fileIds: [ID!]!) {
          formUploadCacheRemove(formId: $formId, fileIds: $fileIds) {
            success
          }
        }
      QUERY
    end
    let(:form_id)           { 12_345 }
    let(:upload_cache_file) { UploadCache.new(form_id).add(filename: file_name, data: file_content, created_by_id: 1) }
    let(:file_name)         { 'my_testfile.pdf' }
    let(:file_type)         { 'application/pdf' }
    let(:file_content)      { 'some test content' }
    let(:variables)         { { formId: form_id, fileIds: [ gql.id(upload_cache_file) ] } }

    before do
      gql.execute(query, variables: variables)
    end

    it 'responds with success' do
      expect(gql.result.data).to eq({ 'success' => true })
    end

    it 'deletes upload cache entry' do
      expect(Store.find_by(id: upload_cache_file.id)).to be_nil
    end

    context 'when trying to delete a missing file' do
      before do
        # Execute query a second time
        gql.execute(query, variables: variables)
      end

      it 'fails' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
