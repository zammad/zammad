# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::AttachmentReferenceRemove do
  let(:attachment) { create(:store, :image, object: 'Ticket::Article', o_id: create(:ticket_article).id) }

  describe '.run' do
    subject(:mail) { { body: body, content_type: content_type } }

    let(:content_type) { 'text/html' }

    before do
      described_class.run(nil, mail, {})
    end

    context 'with a reference to a local attachment' do
      let(:body) { %(<div><img src="/api/v1/attachments/#{attachment.id}">some text</div>) }

      it 'removes the image' do
        expect(mail[:body]).to eq('<div>some text</div>')
      end
    end

    context 'with a reference to a local ticket attachment' do
      let(:body) { %(<div><img src="/api/v1/ticket_attachment/1/2/#{attachment.id}?view=inline">some text</div>) }

      it 'removes the image' do
        expect(mail[:body]).to eq('<div>some text</div>')
      end
    end

    context 'with an escaped reference to a local attachment' do
      let(:body) { %(<div><img src="%2fapi%2fv1%2fattachments%2f#{attachment.id}">some text</div>) }

      it 'removes the image' do
        expect(mail[:body]).to eq('<div>some text</div>')
      end
    end

    context 'with an invalid percent encoded reference' do
      let(:body) { %(<div><img src="%FFapi/v1/attachments/#{attachment.id}">some text</div>) }

      it 'keeps the body untouched' do
        expect(mail[:body]).to eq(body)
      end
    end

    context 'with whitespace inside the reference' do
      let(:body) { %(<div><img src="/api/v1/\tattachments/#{attachment.id}">some text</div>) }

      it 'removes the image' do
        expect(mail[:body]).to eq('<div>some text</div>')
      end
    end

    context 'with an inline data image' do
      let(:body) { '<div><img src="data:image/png;base64,iVBORw0KGgo=">some text</div>' }

      it 'keeps the image' do
        expect(mail[:body]).to eq(body)
      end
    end

    context 'with a content id image' do
      let(:body) { '<div><img src="cid:some_content_id@example.com">some text</div>' }

      it 'keeps the image' do
        expect(mail[:body]).to eq(body)
      end
    end

    context 'with a plain text body' do
      let(:content_type) { 'text/plain' }
      let(:body)         { %(<img src="/api/v1/attachments/#{attachment.id}">) }

      it 'keeps the body untouched' do
        expect(mail[:body]).to eq(body)
      end
    end
  end

  describe 'incoming email', :aggregate_failures do
    let(:raw_mail) do
      <<~MAIL
        From: customer@example.com
        To: zammad@example.com
        Subject: some subject
        Message-ID: <some_message_id@example.com>
        Content-Type: text/html; charset=UTF-8

        <div><img src="/api/v1/attachments/#{attachment.id}">some text</div>
      MAIL
    end

    it 'does not store the reference in the article body' do
      _ticket, article, _user = Channel::EmailParser.new.process(Channel.new(options: {}), raw_mail)

      expect(article.body).to include('some text')
      expect(article.body).not_to include("/api/v1/attachments/#{attachment.id}")
    end
  end
end
