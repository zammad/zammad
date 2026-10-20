# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailBuild > Inline Image Scrub Failure', aggregate_failures: true, type: :model do
  let(:mail) do
    Channel::EmailBuild.build(
      from:         'sender@example.com',
      to:           'recipient@example.com',
      body:         '<p>body <img src="cid:1@zammad.example.com"></p>',
      content_type: 'text/html',
    )
  end

  before do
    allow(ScrubHtml).to receive(:new).and_raise(StandardError, 'scrub failed')
    allow(Rails.logger).to receive(:error)
  end

  context 'when scrubbing the html part for inline images raises' do
    it 'logs the error and still builds the mail' do
      expect(mail.html_part.body.to_s).to include('body')
      expect(Rails.logger).to have_received(:error).with(an_instance_of(StandardError))
    end
  end
end
