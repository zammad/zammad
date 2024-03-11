# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Validations::TicketArticleValidator::WhatsappMessage do
  it 'is called when a whatsapp ticket article is created' do
    expect_any_instance_of(described_class).to receive(:validate)

    create(:whatsapp_article)
  end

  it 'calls validations when an outgoing whatsapp ticket article is created' do
    expect_any_instance_of(described_class).to receive(:validate_body)

    create(:whatsapp_article, sender_name: 'Agent')
  end

  it 'does not call validations when an incoming whatsapp ticket article is created' do
    expect_any_instance_of(described_class).not_to receive(:validate_body)

    create(:whatsapp_article)
  end

  describe '#validate' do
    let(:ticket) { create(:whatsapp_ticket) }

    it 'allows blank body with attachment' do
      instance = build(:whatsapp_article,
                       :with_prepended_attachment,
                       sender_name: 'Agent',
                       ticket:,
                       body:        '')

      described_class.new(instance).validate

      expect(instance.errors).to be_blank
    end

    it 'requires body without attachments' do
      instance = build(:whatsapp_article,
                       sender_name: 'Agent',
                       ticket:,
                       body:        '')

      described_class.new(instance).validate

      expect(instance.errors).to have_attributes(
        errors: include(have_attributes(message: match(%r{Text or attachment is required})))
      )
    end

    it 'allows body' do
      instance = build(:whatsapp_article, :with_prepended_attachment, ticket:, body: 'sample text')

      described_class.new(instance).validate

      expect(instance.errors).to be_blank
    end

    it 'does not allow body with some attachment types' do
      instance = build(:whatsapp_article,
                       :with_prepended_attachment,
                       sender_name:           'Agent',
                       ticket:,
                       body:                  'sample text',
                       override_content_type: 'audio/ogg')

      described_class.new(instance).validate

      expect(instance.errors).to have_attributes(
        errors: include(have_attributes(message: match(%r{Audio file is sent without text caption})))
      )
    end

    it 'allows no attachments' do
      instance = build(:whatsapp_article,
                       sender_name: 'Agent',
                       ticket:)

      described_class.new(instance).validate

      expect(instance.errors).to be_blank
    end

    it 'allows 1 attachment' do
      instance = build(:whatsapp_article,
                       :with_prepended_attachment,
                       sender_name: 'Agent',
                       ticket:)

      described_class.new(instance).validate

      expect(instance.errors).to be_blank
    end

    it 'does not allow multiple attachments' do
      instance = build(:whatsapp_article,
                       :with_prepended_attachment,
                       sender_name:       'Agent',
                       ticket:,
                       attachments_count: 2)

      described_class.new(instance).validate

      expect(instance.errors).to have_attributes(
        errors: include(have_attributes(message: match(%r{Only 1 attachment allowed})))
      )
    end

    it 'checks attachment size' do
      stub_const("#{described_class}::CONTENT_TYPE_OPTIONS", [
                   { size: 10, identifier: :document, label: __('Document file') },
                 ])

      instance = build(:whatsapp_article,
                       :with_prepended_attachment,
                       sender_name: 'Agent',
                       ticket:)

      described_class.new(instance).validate

      expect(instance.errors).to have_attributes(
        errors: include(have_attributes(message: match(%r{File is too big. Document file has to be 10 Bytes or smaller.})))
      )
    end

    it 'checks attachment type' do
      instance = build(:whatsapp_article, :with_prepended_attachment,
                       sender_name: 'Agent',
                       ticket:,
                       attachment:  File.open('spec/fixtures/files/upload/test.rtf'))

      described_class.new(instance).validate

      expect(instance.errors).to have_attributes(
        errors: include(have_attributes(message: match(%r{File format is not allowed: application/rtf})))
      )
    end
  end
end
