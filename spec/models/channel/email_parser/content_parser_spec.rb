# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::EmailParser::ContentParser, :aggregate_failures do
  describe '#message_body_hash' do
    subject(:result) { described_class.new(mail).message_body_hash }

    context 'with an encrypted PGP/MIME message without a visible body' do
      let(:mail) do
        Mail.new(Rails.root.join('spec/fixtures/files/pgp/mail/mail-attached.box').read)
      end

      it 'uses the decoded encrypted MIME part as its text body' do
        expect(result[:body]).to eq(mail.parts.second.body.decoded)
        expect(result[:content_type]).to eq('text/plain')
        expect(result[:attachments].pluck(:filename)).to contain_exactly('file', 'encrypted.asc')
      end
    end

    context 'with an ordinary attachment named encrypted.asc' do
      let(:mail) do
        Mail.new.tap do |message|
          message.add_file(filename: 'encrypted.asc', content: 'not a PGP/MIME message')
        end
      end

      it 'does not treat the attachment as the message body' do
        expect(result[:body]).to eq('no visible content')
      end
    end
  end
end
