# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UploadCache do
  subject(:upload_cache) { described_class.new(form_id) }

  let(:form_id) { SecureRandom.uuid }

  # required for adding items to the Store
  before { UserInfo.current_user_id = 1 }

  describe '#add' do

    it 'adds a Store item' do
      expect do
        upload_cache.add(
          data:        'content_file3_normally_should_be_an_image',
          filename:    'some_file3.jpg',
          preferences: {
            'Content-Type'        => 'image/jpeg',
            'Mime-Type'           => 'image/jpeg',
            'Content-Disposition' => 'attached',
          },
        )
      end.to change(Store, :count).by(1)
    end
  end

  describe '#attachments' do

    before do
      upload_cache.add(
        data:        'hello world',
        filename:    'some.txt',
        preferences: {
          'Content-Type' => 'text/plain',
        },
      )
    end

    it 'returns all Store items' do
      attachments = upload_cache.attachments

      expect(attachments.count).to be(1)
      expect(attachments).to include(Store.last)
    end
  end

  describe '#destroy' do

    before do
      upload_cache.add(
        data:        'hello world',
        filename:    'some.txt',
        preferences: {
          'Content-Type' => 'text/plain',
        },
      )

      upload_cache.add(
        data:        'hello other world',
        filename:    'another_some.txt',
        preferences: {
          'Content-Type' => 'text/plain',
        },
      )
    end

    it 'removes all added Store items' do
      expect { upload_cache.destroy }.to change(Store, :count).by(-2)
    end
  end

  describe '#remove_item' do

    before do
      upload_cache.add(
        data:        'hello world',
        filename:    'some.txt',
        preferences: {
          'Content-Type' => 'text/plain',
        },
      )
    end

    it 'removes the Store item matching the given ID' do
      expect { upload_cache.remove_item(Store.last.id) }.to change(Store, :count).by(-1)
    end

    it 'prevents removage of non UploadCache Store items' do

      item = create(:store,
                    object:      'Ticket',
                    o_id:        1,
                    data:        "Can't touch this",
                    filename:    'keep.txt',
                    preferences: {
                      'Content-Type' => 'text/plain',
                    },)

      expect { upload_cache.remove_item(item.id) }.to raise_error(Exceptions::UnprocessableEntity)
    end

    it 'fails for non existing UploadCache Store items' do
      expect { upload_cache.remove_item(form_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.files_include_attachment?' do
    let(:files) do
      [
        { name: 'name.jpg', type: 'image/jpg' },
        { name: 'name.png', type: 'wrong' },
        { name: 'name2.exe' },
        { name: 'other.jpg' }
      ]
    end

    context 'when one of files match by name' do
      let(:attachment) { create(:store, :image, filename: 'other.jpg') }

      it 'returns true' do
        expect(described_class).to be_files_include_attachment files, attachment
      end
    end

    context 'when one of files match by name but not type' do
      let(:attachment) { create(:store, :image, filename: 'name.png') }

      it 'returns false' do
        expect(described_class).not_to be_files_include_attachment files, attachment
      end
    end

    context 'when one of files match by name and type' do
      let(:attachment) { create(:store, :image, filename: 'name.jpg') }

      it 'returns true' do
        expect(described_class).to be_files_include_attachment files, attachment
      end
    end

    context 'when no files match' do
      let(:attachment) { create(:store, :txt) }

      it 'returns false' do
        expect(described_class).not_to be_files_include_attachment files, attachment
      end
    end
  end
end
