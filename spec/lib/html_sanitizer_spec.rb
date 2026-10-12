# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer, :aggregate_failures do
  describe '.replace_inline_images' do
    it 'replaces base64-encoded inline images by cid images' do
      body, inline_attachments = described_class.replace_inline_images('<img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/...">')

      expect(body).to match(%r{<img src="cid:.+?">})
      expect(inline_attachments).to be_one
    end
  end

  describe '.dynamic_image_size' do
    it 'adds a max-width rule to images' do
      expect(described_class.dynamic_image_size('<img src="/some_one.png">')).to eq('<img src="/some_one.png" style="max-width:100%;">')
    end
  end

  # Issue #2416 - html_sanitizer goes into loop for specific content
  describe '.strict' do
    context 'with strings that take a long time (>10s) to parse' do
      before { allow(Timeout).to receive(:timeout).and_raise(Timeout::Error) }

      it 'returns a timeout error message for the user' do
        expect(described_class.strict(+'<img src="/some_one.png">', true))
          .to match(HtmlSanitizer::UNPROCESSABLE_HTML_MSG)
      end
    end

    context 'with strings that have very deep nested HTML content' do
      before do
        stub_const('Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH', 3)
      end

      it 'collapses empty nested divs and succeeds' do
        # Empty nested divs get collapsed, reducing depth
        expect(described_class.strict('<div><div><div><div></div></div></div></div>'))
          .to eq('')
      end

      it 'collapses empty wrapper divs and preserves content' do
        # Only the innermost div with content is kept
        expect(described_class.strict('<div><div><div><div>content</div></div></div></div>'))
          .to eq('<div>content</div>')
      end

      it 'preserves content at different nesting levels' do
        # Outer div has direct content "outer", middle wrappers get collapsed
        expect(described_class.strict('<div>outer<div><div><div>inner</div></div></div></div>'))
          .to eq('<div>outer<div>inner</div></div>')
      end

      it 'preserves non-div elements and their wrappers' do
        expect(described_class.strict('<div><div><div><div><span>content</span></div></div></div></div>'))
          .to eq('<div><span>content</span></div>')
      end
    end

    context 'with href links that contain square brackets' do
      it 'correctly URL encodes them' do
        expect(described_class.strict(+'<a href="https://example.com/?foo=bar&baz[x]=y">example</a>', true))
          .to eq('<a href="https://example.com/?foo=bar&amp;baz[x]=y" rel="nofollow noreferrer noopener" target="_blank" title="https://example.com/?foo=bar&amp;baz[x]=y">example</a>')
      end
    end

    context 'with href links that contain http urls' do
      it 'correctly URL encodes them' do
        expect(described_class.strict(+'<a href="https://example.com/?foo=https%3A%2F%2Fexample.com%3Flala%3A123">example</a>', true))
          .to eq('<a href="https://example.com/?foo=https%3A%2F%2Fexample.com%3Flala%3A123" rel="nofollow noreferrer noopener" target="_blank" title="https://example.com/?foo=https%3A%2F%2Fexample.com%3Flala%3A123">example</a>')
      end
    end

    context 'with href links that contain Zammad variable placeholders' do
      it 'preserves curly braces in URL' do
        expect(described_class.strict(+'<a href="https://example.com/?no={ticket.number}">example</a>', true))
          .to eq('<a href="https://example.com/?no={ticket.number}" rel="nofollow noreferrer noopener" target="_blank" title="https://example.com/?no={ticket.number}">example</a>')
      end
    end

    context 'when HTML sanitizer is removing attributes/styles which are white listed. #4605' do
      it 'does not remove whitelisted attributes width' do
        expect(described_class.strict('<table width=20><tr width=20><td width=20>123</td></tr></table>')).to eq('<table style="width:20px;"><tbody><tr style="width:20px;"><td style="width:20px;">123</td></tr></tbody></table>')
      end
    end

    context 'when handling <title> tags' do
      let(:source) { '<title>some title</title><p>actual content</p>' }
      let(:target) { '<p>actual content</p>' }

      it 'removes them' do
        expect(described_class.strict(source)).to eq(target)
      end
    end
  end

  describe '.cleanup' do
    context 'with strings that take a long time (>10s) to parse' do
      before { allow(Timeout).to receive(:timeout).and_raise(Timeout::Error) }

      it 'returns a timeout error message for the user' do
        expect(described_class.cleanup(+'<img src="/some_one.png">'))
          .to match(HtmlSanitizer::UNPROCESSABLE_HTML_MSG)
      end
    end
  end
end
