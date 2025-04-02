# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::Avatar::Add, type: :graphql do
  context 'when creating a new avatar for the logged-in user', authenticated_as: :agent do
    let(:agent)         { create(:agent) }
    let(:variables)     { { images: { original: upload, resized: upload } } }
    let(:upload)        { { name: filename, type: type, content: image_data } }
    let(:image_data)    { 'iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==' }
    let(:type)          { 'image/png' }
    let(:filename)      { 'avatar.png' }
    let(:execute_query) { true }

    let(:query) do
      <<~QUERY
        mutation userCurrentAvatarAdd($images: AvatarInput!) {
          userCurrentAvatarAdd(images: $images) {
            avatar {
              id
            }
            errors {
              message
              field
            }
          }
        }
      QUERY
    end

    before do
      next if !execute_query

      gql.execute(query, variables: variables)
    end

    context 'with valid image' do
      it 'returns the newly created avatar' do
        expect(gql.result.data[:avatar]).not_to be_nil
      end

      it 'updates the image for the user' do
        avatar = Gql::ZammadSchema.verified_object_from_id(gql.result.data[:avatar][:id], type: Avatar)
        expect(agent.reload.image).to eq(avatar.store_hash)
      end

      context 'when checking the Store' do
        let(:execute_query) { false }

        it 'increases the amount of records correctly' do
          expect { gql.execute(query, variables: variables) }.to change(Store, :count).by(2)
        end
      end
    end

    context 'with invalid image' do
      let(:image_data) { 'invalid image' }

      it 'fails with error message' do
        expect(gql.result.error_message).to eq('Variable $images of type AvatarInput! was provided invalid value for original.content (invalid base64), resized.content (invalid base64)')
      end
    end

    context 'with invalid mime-type' do
      let(:type) { 'image/tiff' }

      it 'fails with error message' do
        expect(gql.result.data[:errors][0]).to include('message' => 'The MIME type of the image is invalid.')
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
