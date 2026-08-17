# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UploadCache do
  subject(:upload_cache) { described_class.new(form_id) }

  let(:form_id) { SecureRandom.uuid }

  describe '#add' do
    before { UserInfo.current_user_id = 1 }

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
      UserInfo.current_user_id = 1
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
      UserInfo.current_user_id = 1
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
      UserInfo.current_user_id = 1
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

      expect { upload_cache.remove_item(item.id) }.to raise_error(Exceptions::UnprocessableContent)
    end

    it 'fails for non existing UploadCache Store items' do
      expect { upload_cache.remove_item(form_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#destroy scoping' do
    let(:owner)    { create(:user) }
    let(:stranger) { create(:user) }
    let(:cache)    { described_class.new(form_id) }

    before do
      cache.add(
        data:          'owner file',
        filename:      'owner.txt',
        preferences:   { 'Content-Type' => 'text/plain' },
        created_by_id: owner.id,
      )
      cache.add(
        data:          'stranger file',
        filename:      'stranger.txt',
        preferences:   { 'Content-Type' => 'text/plain' },
        created_by_id: stranger.id,
      )
    end

    it 'only removes owners own files' do
      UserInfo.current_user_id = owner.id

      cache.destroy

      expect(cache.attachments(created_by_id: nil).pluck(:created_by_id)).to eq([stranger.id])
    end

    it 'removes all files when called without user context' do
      UserInfo.current_user_id = nil

      cache.destroy

      expect(cache.attachments(created_by_id: nil).count).to eq(0)
    end
  end

  describe '#remove_item (library-level, no ownership check)' do
    let(:owner)    { create(:user) }
    let(:stranger) { create(:user) }
    let(:cache)    { described_class.new(form_id) }

    before do
      cache.add(
        data:          'some file',
        filename:      'some.txt',
        preferences:   { 'Content-Type' => 'text/plain' },
        created_by_id: owner.id,
      )
    end

    it 'allows removal by any user context (library method relies on policy for auth)' do
      store_id = cache.attachments(created_by_id: nil).first.id
      UserInfo.current_user_id = stranger.id

      expect { cache.remove_item(store_id) }.to change(Store, :count).by(-1)
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
