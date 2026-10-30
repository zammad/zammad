# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser process with postmaster filters', type: :model do
  let(:mail) do
    <<~MAIL
      From: me@example.com
      To: customer@example.com
      Subject: some subject

      Some Text
    MAIL
  end

  def process_mail
    Channel::EmailParser.new.process({}, mail)
  end

  it 'runs the configured filters' do
    expect { process_mail }.to change(Ticket, :count).by(1)
  end

  # JSON has no .run, so calling it as a filter would fail the processing with a NoMethodError.
  context 'when a pre filter names a class outside of Channel::Filter' do
    before { Setting.set('0000_postmaster_filter_trusted', 'JSON', validate: false) }

    it 'stops the processing without calling it and creates an error ticket instead', :aggregate_failures do
      ticket, article, = process_mail
      processing_log   = article.attachments.find { |attachment| attachment.preferences['email_unprocessable'] == 'log' }.content

      expect(ticket.title).to eq('Unprocessable email')
      expect(processing_log).to include("'JSON' is not a postmaster filter")
    end
  end

  context 'when a post filter names a class outside of Channel::Filter' do
    before do
      Setting.set('5401_postmaster_filter_jira_check', 'JSON', validate: false)
      allow(Channel::Filter::ServiceNowCheck).to receive(:run)
      allow(Rails.logger).to receive(:error)
    end

    it 'skips it with an error and runs the other post filters', :aggregate_failures do
      expect { process_mail }.to change(Ticket, :count).by(1)
      expect(Rails.logger).to have_received(:error).with(%r{'JSON' is not a postmaster filter})
      expect(Channel::Filter::ServiceNowCheck).to have_received(:run).with(anything, anything, kind_of(Ticket), anything, anything)
    end
  end
end
