# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Avatar, type: :model do
  describe '#add' do
    context 'when providing urls' do
      let(:user)          { create(:agent) }
      let(:headers)       { { 'content-type' => content_type } }
      let(:response_body) { 'some sample image data' }
      let(:avatar_data) do
        {
          object:        'User',
          o_id:          user.id,
          default:       true,
          url:           url,
          source:        'web',
          deletable:     true,
          updated_by_id: 1,
          created_by_id: 1,
        }
      end

      before do
        stub_request(:get, url).to_return(status: 200, body: response_body, headers: headers)

        # to disable generation of previews in the store
        Setting.set('import_mode', true)
      end

      shared_examples 'successful avatar add' do
        it 'creates an avatar' do
          expect(Store.find_by(id: described_class.add(avatar_data).store_full_id)[:preferences].to_h).to include('Mime-Type' => content_type)
        end
      end

      shared_examples 'unsuccessful avatar add' do
        it 'does not create an avatar' do
          expect { described_class.add(avatar_data) }.not_to change(Store, :count)
        end
      end

      context 'when the url does not have a file ending' do
        let(:content_type) { 'image/png' }
        let(:url)          { 'https://zammad.org/avatar' }

        include_examples 'successful avatar add'
      end

      context 'when the url has a file ending' do
        let(:content_type) { 'image/jpeg' }
        let(:url)          { 'https://zammad.org/avatar.jpg' }

        include_examples 'successful avatar add'
      end

      context 'when a not allowed content-type is used' do
        let(:content_type) { 'image/tiff' }
        let(:url)          { 'https://zammad.org/avatar' }

        include_examples 'unsuccessful avatar add'
      end
    end
  end
end
