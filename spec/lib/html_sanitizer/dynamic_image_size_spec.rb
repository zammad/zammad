# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::DynamicImageSize do
  describe('#sanitize') do
    subject(:sanitized) { described_class.new.sanitize(input) }

    let(:input)  { '<img src="...">' }
    let(:target) { '<img src="..." style="max-width:100%;">' }

    it { expect(sanitized).to eq target }
  end
end
