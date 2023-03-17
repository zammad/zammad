# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Scrubber::Base do
  let(:scrubber) { described_class.new }

  describe '#html_decode' do
    it 'converts html entities into chars' do
      input = '"&lt;tag&gt;" &amp; &quot;&nbsp;&quot;'
      output = scrubber.send(:html_decode, input)

      expect(output).to eq '"<tag>" & " "'
    end
  end
end
