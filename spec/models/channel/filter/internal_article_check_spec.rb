# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::InternalArticleCheck do
  let(:ticket) { create(:ticket) }
  let(:vendor_email) { 'vendor@example.com' }
  let(:article_to) { vendor_email }
  let(:from) { "From: <#{vendor_email}>" }
  let(:message_id) { 'some_message_id_999@example.com' }
  let(:in_reply_to) { message_id }
  let(:subject) { "Subject: #{ticket.subject_build('some subject')}" }
  let(:ticket_article) { build(:ticket_article, ticket: ticket, to: article_to, internal: false, message_id: message_id) }
  let(:inbound_email) { create(:ticket_article, :inbound_email, ticket: ticket) }
  let(:outbound_email) { create(:ticket_article, :outbound_email, ticket: ticket) }
  let(:internal_note) { create(:ticket_article, :outbound_note, ticket: ticket, internal: true) }

  let(:email_raw_string) do
    email_file_path = Rails.root.join('test/data/mail/mail001.box')
    File.read(email_file_path)
  end

  let(:email_parse_mail_answer) do
    channel_as_model = Channel.new(options: {})

    email_raw_string.sub!(%r{^Subject: .+?$}, subject)
    email_raw_string.sub!('From: <John.Smith@example.com>', from)
    email_raw_string.sub!('Message-Id: <053EA3703574649ABDAF24D43A05604F327A130@MEMASFRK004.example.com>', "Message-Id: <053EA3703574649ABDAF24D43A05604F327A130@MEMASFRK004.example.com>\nIn-Reply-To: #{in_reply_to}")
    Channel::EmailParser.new.process(channel_as_model, email_raw_string)
  end

  shared_examples 'setting new article to internal' do
    it 'sets new article to internal' do
      _ticket_p, article_p, _user_p = email_parse_mail_answer
      expect(article_p.internal).to be true
    end
  end

  shared_examples 'not setting new article to internal' do
    it 'does not set new article to internal' do
      _ticket_p, article_p, _user_p = email_parse_mail_answer
      expect(article_p.internal).not_to be true
    end
  end

  shared_examples 'sets new article to internal' do
    context 'when From has email only' do
      it_behaves_like 'setting new article to internal'
    end

    context 'when From have both name and email' do
      let(:from) { "From: Some Vendor Name <#{vendor_email}>" }

      it_behaves_like 'setting new article to internal'
    end

    context 'when From have name with brackets and email' do
      let(:from) { "From: (Some Vendor Name) <#{vendor_email}>" }

      it_behaves_like 'setting new article to internal'
    end

    context 'when From have name with brackets and uppercase email' do
      let(:from) { "From: (Some Vendor Name) <#{vendor_email.upcase}>" }

      it_behaves_like 'setting new article to internal'
    end

    context 'when From have name in quotes and email' do
      let(:from) { "From: 'Günther John | Example GmbH' <#{vendor_email}>" }

      it_behaves_like 'setting new article to internal'
    end

    context 'when From have email before name' do
      let(:from) { "From: <#{vendor_email.upcase}> (Some Vendor Name)" }

      it_behaves_like 'setting new article to internal'
    end

    context 'when article to have both name and email' do
      let(:article_to) { "Some Vendor Name <#{vendor_email}>" }

      it_behaves_like 'setting new article to internal'
    end

    context 'when article to have name with brackets and email' do
      let(:article_to) { "(Some Vendor Name) <#{vendor_email}>" }

      it_behaves_like 'setting new article to internal'
    end

    context 'when article to have name with brackets and uppercase email' do
      let(:article_to) { "(Some Vendor Name) <#{vendor_email.upcase}>" }

      it_behaves_like 'setting new article to internal'
    end

    context 'when article to have name in quotes and email' do
      let(:article_to) { "'Günther John | Example GmbH' <#{vendor_email}>" }

      it_behaves_like 'setting new article to internal'
    end

    context 'when article to have email before name' do
      let(:article_to) { "<#{vendor_email}> (Some Vendor Name)" }

      it_behaves_like 'setting new article to internal'
    end
  end

  shared_examples 'checks in reply to header' do

    context 'when associated article is internal' do
      before { ticket_article.update! internal: true }

      include_examples 'sets new article to internal'
    end

    context 'when there is no associated article' do
      let(:article_to) { 'me@example.com' }

      it_behaves_like 'not setting new article to internal'
    end

    context 'when associated article is not internal' do
      before { ticket_article.update! internal: false }

      it_behaves_like 'not setting new article to internal'
    end

  end

  shared_examples 'checks last outgoing mail' do

    context 'when associated article is internal' do
      before { ticket_article.update! internal: true }

      include_examples 'sets new article to internal'
    end

    context 'when there is no associated article' do
      let(:article_to) { nil }

      it_behaves_like 'not setting new article to internal'
    end

    context 'when associated article is not internal' do
      before { ticket_article.update! internal: false }

      it_behaves_like 'not setting new article to internal'
    end

    context 'when From have wrong email format' do
      let(:from) { "From: 'Günther John | Example GmbH' <power quadrant #{vendor_email}>" }

      it_behaves_like 'not setting new article to internal'
    end

    context 'when article to have wrong email format' do
      let(:article_to) { "'Günther John | Example GmbH' <power quadrant #{vendor_email}>" }

      it_behaves_like 'not setting new article to internal'
    end

    context 'when there is no article to can not be parsed' do
      let(:article_to) { "From: (Some Vendor Name) <#{vendor_email.upcase}>" }

      it_behaves_like 'not setting new article to internal'
    end

  end

  describe '.run' do
    before { inbound_email && outbound_email && internal_note }

    context 'when in reply to header is present' do

      include_examples 'checks in reply to header'
    end

    context 'when in reply to header is blank' do
      let(:in_reply_to) { '' }

      include_examples 'checks last outgoing mail'
    end
  end
end
