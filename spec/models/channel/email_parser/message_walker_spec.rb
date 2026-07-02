# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::EmailParser::MessageWalker do
  describe '#body_text' do
    subject(:walker) { described_class.new(mail) }

    let(:mail) { instance_double(Mail::Message, parts: []) }

    context 'when the HTML body contains more than 5,000 links' do
      let(:part) do
        instance_double(
          Mail::Part,
          body:         double(to_s: ('<a href="#">x</a> ' * 5_001), raw_source: ''),
          charset:      'UTF-8',
          content_type: 'text/html',
        )
      end

      it 'returns EXCESSIVE_LINKS_MSG as the body' do
        body, = walker.send(:body_text, part, strict_html: true)
        expect(body).to eq(Channel::EmailParser::EXCESSIVE_LINKS_MSG)
      end

      it 'sets body_rendering_error: true in sanitized_body_info' do
        _, sanitized_body_info = walker.send(:body_text, part, strict_html: true)
        expect(sanitized_body_info[:body_rendering_error]).to be(true)
      end
    end
  end
end
