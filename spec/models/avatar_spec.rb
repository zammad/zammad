# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Avatar, type: :model do
  describe '#add' do
    let(:user)       { create(:agent) }
    let(:png_image)  { Rails.root.join('spec/fixtures/files/image/small.png').binread }
    let(:jpeg_image) { "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00".b }
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
      # to disable generation of previews in the store
      Setting.set('import_mode', true)
    end

    shared_examples 'successful avatar add' do
      it 'creates an avatar with the detected mime type' do
        expect(Store.find_by(id: described_class.add(avatar_data).store_full_id)[:preferences].to_h).to include('Mime-Type' => mime_type)
      end
    end

    shared_examples 'unsuccessful avatar add' do
      it 'does not create an avatar' do
        expect { described_class.add(avatar_data) }.not_to change(Store, :count)
      end
    end

    context 'when providing urls' do
      let(:url)           { 'https://zammad.org/avatar' }
      let(:content_type)  { 'image/png' }
      let(:headers)       { { 'content-type' => content_type } }
      let(:response_body) { png_image }

      before do
        stub_request(:get, url).to_return(status: 200, body: response_body, headers: headers)
      end

      context 'when the url does not have a file ending' do
        let(:mime_type) { 'image/png' }

        include_examples 'successful avatar add'
      end

      context 'when the url has a file ending' do
        let(:url)           { 'https://zammad.org/avatar.jpg' }
        let(:content_type)  { 'image/jpeg' }
        let(:response_body) { jpeg_image }
        let(:mime_type)     { 'image/jpeg' }

        include_examples 'successful avatar add'
      end

      context 'when the content-type does not match the content' do
        let(:content_type) { 'application/octet-stream' }
        let(:mime_type)    { 'image/png' }

        include_examples 'successful avatar add'
      end

      context 'when the url and the content-type claim an image but the content is none' do
        let(:url)           { 'https://zammad.org/_search?q=x.png' }
        let(:response_body) { '{"took":1}' }

        include_examples 'unsuccessful avatar add'
      end

      context 'when a not allowed image type is used' do
        let(:content_type)  { 'image/tiff' }
        let(:response_body) { "II*\x00".b }

        include_examples 'unsuccessful avatar add'
      end

      context 'when the response exceeds the size limit' do
        let(:headers) { { 'content-type' => content_type, 'content-length' => (described_class::MAX_IMAGE_SIZE + 1).to_s } }

        include_examples 'unsuccessful avatar add'
      end
    end

    context 'when providing a tempfile' do
      let(:url) do
        Tempfile.new(['avatar', extension]).tap do |file|
          file.binmode
          file.write(content)
          file.rewind
        end
      end

      after { url.close! }

      context 'when the file name does not match the content' do
        let(:extension) { '.txt' }
        let(:content)   { png_image }
        let(:mime_type) { 'image/png' }

        include_examples 'successful avatar add'
      end

      context 'when the file name claims an image but the content is none' do
        let(:extension) { '.png' }
        let(:content)   { 'not an image' }

        include_examples 'unsuccessful avatar add'
      end

      context 'when the file exceeds the size limit' do
        let(:extension) { '.png' }
        let(:content)   { png_image + ("\x00" * described_class::MAX_IMAGE_SIZE) }

        include_examples 'unsuccessful avatar add'
      end
    end
  end
end
