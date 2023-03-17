# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Cleanup do
  describe('#sanitize') do
    it 'cleans up string' do
      input  = '<a:z></a:z><div>asd<b><i></i></b></div>'
      target = '<div>asd</div>'

      expect(described_class.new.sanitize(input)).to eq target
    end
  end
end
