# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::ReplaceInlineImages do
  describe('#sanitize') do
    let(:sanitized) { described_class.new.sanitize(input, 'prefix') }
    let(:input)     { '<img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/...">' }
    let(:target)    { %r{<img src="cid:.+?">} }

    it { expect(sanitized.first).to match(target) }
    it { expect(sanitized.last).to include(include(filename: 'image1.jpeg')) }
  end
end
