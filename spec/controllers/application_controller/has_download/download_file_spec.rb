# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationController::HasDownload::DownloadFile do
  subject(:download_file) { described_class.new(stored_file.id, disposition: 'inline') }

  let(:file_content_type) { 'application/pdf' }
  let(:file_data)         { 'A example file.' }
  let(:file_name)         { 'example.pdf' }

  let(:stored_file) do
    create(:store,
           object:        'Ticket',
           o_id:          1,
           data:          file_data,
           filename:      file_name,
           preferences:   {
             'Content-Type' => file_content_type,
           },
           created_by_id: 1,)
  end

  describe '#disposition' do
    context "with given object dispostion 'inline'" do
      context 'with allowed inline content type (from ActiveStorage.content_types_allowed_inline)' do
        it 'disposition is inline' do
          expect(download_file.disposition).to eq('inline')
        end
      end

      context 'with binary content type (ActiveStorage.content_types_to_serve_as_binary)' do
        let(:file_content_type) { 'image/svg+xml' }

        it 'disposition forced to attachment' do
          expect(download_file.disposition).to eq('attachment')
        end
      end
    end

    context "with given object dispostion 'attachment'" do
      subject(:download_file) { described_class.new(stored_file.id, disposition: 'attachment') }

      it 'disposition is attachment' do
        expect(download_file.disposition).to eq('attachment')
      end
    end
  end

  describe '#content_type' do
    context 'with none binary content type' do
      it 'check content type' do
        expect(download_file.content_type).to eq('application/pdf')
      end
    end

    context 'with forced active storage binary content type' do
      let(:file_content_type) { 'image/svg+xml' }

      it 'check content type' do
        expect(download_file.content_type).to eq('application/octet-stream')
      end
    end
  end

  describe '#content' do
    context 'with not resizable file' do
      it 'check that normal content will be returned' do
        expect(download_file.content('preview')).to eq('A example file.')
      end
    end

    context 'with image content type' do
      let(:file_content_type) { 'image/jpg' }
      let(:file_data) { Rails.root.join('test/data/upload/upload2.jpg').binread }
      let(:file_name) { 'image.jpg' }

      it 'check that inline content will be returned' do
        expect(download_file.content('inline')).to not_eq(file_data)
      end

      it 'check that preview content will be returned' do
        expect(download_file.content('preview')).to not_eq(file_data)
      end
    end
  end
end
