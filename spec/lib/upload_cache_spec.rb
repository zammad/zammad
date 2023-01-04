# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UploadCache do

  subject(:upload_cache) { described_class.new(1337) }

  # required for adding items to the Store
  before { UserInfo.current_user_id = 1 }

  describe '#initialize' do

    it 'converts given (form_)id to an Integer' do
      expect(described_class.new('1337').id).to eq(1337)
    end
  end

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
      expect { upload_cache.remove_item(1337) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
