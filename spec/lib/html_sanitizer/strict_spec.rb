# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Strict do
  describe('#sanitize') do
    it 'cleans up string' do
      input  = '<div class="to-be-removed">test</div><script>alert();</script>'
      target = '<div>test</div>'

      expect(described_class.new.sanitize(input)).to eq target
    end

    it 'cleans up full html' do
      input  = '<html><body><div style="font-family: Meiryo, メイリオ, &quot;Hiragino Sans&quot;, sans-serif; font-size: 12pt; color: rgb(0, 0, 0);">このアドレスへのメルマガを解除してください。</div></body></html>'
      target = '<div>このアドレスへのメルマガを解除してください。</div>'

      expect(described_class.new.sanitize(input)).to eq target
    end
  end
end
