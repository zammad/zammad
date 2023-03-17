# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UploadCacheCleanupJob, type: :job do
  context 'when upload cache exists' do
    let(:upload_cache) { UploadCache.new(1337) }

    before do
      UserInfo.current_user_id = 1

      upload_cache.add(
        data:        'current example',
        filename:    'current.txt',
        preferences: {
          'Content-Type' => 'text/plain',
        },
      )

      travel_to 1.month.ago

      # create one taskbar and related upload cache entry, which should not be deleted
      create(:taskbar, state: { form_id: 9999 })
      UploadCache.new(9999).add(
        data:        'Some Example with related Taskbar',
        filename:    'another_example_with_taskbar.txt',
        preferences: {
          'Content-Type' => 'text/plain',
        }
      )

      3.times do
        upload_cache.add(
          data:        'hello world',
          filename:    'some.txt',
          preferences: {
            'Content-Type' => 'text/plain',
          },
        )
      end

      travel_back
    end

    it 'cleanup the store items which are expired with job' do
      expect { described_class.perform_now }.to change(Store, :count).by(-3)
    end
  end

  context 'when upload cache does not exist' do
    it 'does not crash' do
      expect { described_class.perform_now }.not_to raise_error
    end
  end
end
