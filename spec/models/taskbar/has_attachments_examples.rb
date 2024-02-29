# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.shared_examples 'Taskbar::HasAttachments' do
  let(:form_id) { SecureRandom.uuid }

  describe '.with_form_id' do
    before do
      create(:taskbar)
      create_list(:taskbar, 2, state: { form_id: form_id })
    end

    it 'get list of all form ids' do
      expect(described_class.with_form_id.filter_map(&:persisted_form_id)).to eq([form_id, form_id])
    end
  end

  describe 'delete attachments in upload cache' do
    let(:state) { nil }

    let(:taskbar) do
      taskbar = create(:taskbar, state: state)
      UploadCache.new(form_id).add(
        data:        'Some Example',
        filename:    'another_example.txt',
        preferences: {
          'Content-Type' => 'text/plain',
        }
      )
      taskbar
    end

    # required for adding items to the Store
    before do
      UserInfo.current_user_id = 1

      # initialize taskbar to have different store counts in expect test
      taskbar
    end

    context 'when ticket create' do
      let(:state) do
        { form_id: form_id }
      end

      it 'delete attachments in upload cache after destroy' do
        expect { taskbar.destroy }.to change(Store, :count).by(-1)
      end
    end

    context 'when ticket zoom' do
      let(:state) do
        { ticket: {}, article: { form_id: form_id } }
      end

      it 'delete attachments in upload cache after destroy' do
        expect { taskbar.destroy }.to change(Store, :count).by(-1)
      end
    end
  end
end
