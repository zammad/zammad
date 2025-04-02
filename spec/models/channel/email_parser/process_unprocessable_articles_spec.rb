# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser#reprocess_failed_articles', aggregate_failures: true, type: :model do
  context 'when receiving unprocessable article' do
    before do
      allow_any_instance_of(HtmlSanitizer::Strict).to receive(:run_sanitization).and_raise(Timeout::Error, HtmlSanitizer::UNPROCESSABLE_HTML_MSG)
      parser = Channel::EmailParser.new
      begin
        parser.process({}, File.read('test/data/mail/mail001.box'))
      rescue
        # expected
      end
    end

    it 'does reprocess the unprocessable article' do
      expect(Ticket::Article.last.body).to eq(HtmlSanitizer::UNPROCESSABLE_HTML_MSG)
      allow_any_instance_of(HtmlSanitizer::Strict).to receive(:run_sanitization).and_call_original
      Channel::EmailParser.reprocess_failed_articles
      expect(Ticket::Article.last.body).not_to eq(HtmlSanitizer::UNPROCESSABLE_HTML_MSG)
    end
  end
end
