# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::Answer::Update::Validator::ConcurrentAttachmentChange, type: :model do
  subject(:validator) { described_class.new(user:, answer:, answer_data:) }

  let(:user)     { create(:user, roles: [create(:role, permission_names: 'knowledge_base.editor')]) }
  let(:answer)   { create(:knowledge_base_answer) }
  let(:form_id)  { SecureRandom.uuid }

  let(:answer_data) { { form_id: form_id, known_attachments: known_attachments } }
  let(:known_attachments) { [] }

  def add_answer_attachment(filename, data)
    UserInfo.with_user_id(user.id) do
      Store.create!(object: 'KnowledgeBase::Answer', o_id: answer.id, data: data, filename: filename,
                    preferences: { 'Content-Type': 'text/plain' })
    end
  end

  context 'when the answer has no attachments and the form knew of none' do
    it 'passes' do
      expect { validator.valid! }.not_to raise_error
    end
  end

  context 'when the form was opened with the files the answer still has' do
    let(:known_attachments) { [{ name: 'a.txt', size: 3 }] }

    before { add_answer_attachment('a.txt', 'abc') }

    it 'passes' do
      expect { validator.valid! }.not_to raise_error
    end
  end

  # The case that loses data: saving would replay a cache seeded before their file existed, and
  #   `attach_upload_cache` deletes what the cache does not contain.
  context 'when somebody else added a file after the form was opened' do
    let(:known_attachments) { [{ name: 'a.txt', size: 3 }] }

    before do
      add_answer_attachment('a.txt', 'abc')
      add_answer_attachment('theirs.txt', 'xyz')
    end

    it 'refuses' do
      expect { validator.valid! }.to raise_error(described_class::Error)
    end
  end

  context 'when somebody else removed a file after the form was opened' do
    let(:known_attachments) { [{ name: 'a.txt', size: 3 }, { name: 'gone.txt', size: 3 }] }

    before { add_answer_attachment('a.txt', 'abc') }

    it 'refuses' do
      expect { validator.valid! }.to raise_error(described_class::Error)
    end
  end

  # Same name, different content: identified by name *and* size, because the upload cache holds
  #   copies whose ids are not the answer's and cannot be compared.
  context 'when a file of the same name has a different size' do
    let(:known_attachments) { [{ name: 'a.txt', size: 3 }] }

    before { add_answer_attachment('a.txt', 'much longer content') }

    it 'refuses' do
      expect { validator.valid! }.to raise_error(described_class::Error)
    end
  end

  # A caller with no form has no seeded cache to be stale, and nothing is replayed either.
  context 'without a form id' do
    let(:answer_data) { { known_attachments: [] } }

    before { add_answer_attachment('theirs.txt', 'xyz') }

    it 'passes' do
      expect { validator.valid! }.not_to raise_error
    end
  end

  # An integration or a script sends no baseline; it cannot be checked, and must not be blocked.
  context 'without a known attachment list' do
    let(:answer_data) { { form_id: form_id } }

    before { add_answer_attachment('theirs.txt', 'xyz') }

    it 'passes' do
      expect { validator.valid! }.not_to raise_error
    end
  end

  # Inline images belong to the body, not to the field, and are never replayed from the cache.
  context 'with an inline image on the answer' do
    let(:known_attachments) { [] }

    before do
      UserInfo.with_user_id(user.id) do
        Store.create!(object: 'KnowledgeBase::Answer', o_id: answer.id, data: 'img', filename: 'inline.png',
                      preferences: { 'Content-Type': 'image/png', 'Content-Disposition': 'inline' })
      end
    end

    it 'passes' do
      expect { validator.valid! }.not_to raise_error
    end
  end
end
