# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_audit_logs_examples'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/application_model/has_cache_examples'

RSpec.describe Signature, type: :model do
  it_behaves_like 'HasAuditLogs', update_attribute: 'name', update_value: 'Some updated name'
  it_behaves_like 'HasCollectionUpdate', collection_factory: :signature
  it_behaves_like 'HasXssSanitizedNote', model_factory: :signature
  it_behaves_like 'Association clears cache', association: :groups

  describe 'body sanitization' do
    it 'keeps font color styling of pasted content (#6251)' do
      signature = create(:signature, body: 'Hello <span style="color: #ff0000;">red</span> world')
      signature.reload

      expect(signature.body).to include('<span style="color: #ff0000;">red</span>')
    end
  end

  describe 'picking up upload cache attachments (HasRichText)', current_user_id: -> { user.id } do
    let(:user)    { create(:agent) }
    let(:form_id) { SecureRandom.uuid }

    def add_upload_cache(created_by:, filename: 'hello.txt')
      UserInfo.with_user_id(created_by.id) do
        UploadCache.new(form_id).add(
          filename:      filename,
          data:          'Hello, World!',
          preferences:   { 'Content-Type' => 'text/plain' },
          created_by_id: created_by.id
        )
      end
    end

    context 'with own upload cache' do
      before { add_upload_cache(created_by: user) }

      it 'imports the cached attachments' do
        signature = create(:signature, form_id: form_id)

        expect(signature.attachments.count).to eq(1)
      end
    end

    context "with another user's upload cache" do
      before { add_upload_cache(created_by: create(:agent)) }

      it 'does not import foreign cached attachments' do
        signature = create(:signature, form_id: form_id)

        expect(signature.attachments.count).to eq(0)
      end
    end

    context 'with mixed own and foreign upload cache' do
      before do
        add_upload_cache(created_by: user)
        add_upload_cache(created_by: create(:agent), filename: 'foreign.txt')
      end

      it 'imports only own cached attachments' do
        signature = create(:signature, form_id: form_id)

        expect(signature.attachments.count).to eq(1)
      end

      it 'does not import foreign cached attachments' do
        signature = create(:signature, form_id: form_id)

        expect(signature.attachments.map(&:filename)).not_to include('foreign.txt')
      end
    end
  end
end
