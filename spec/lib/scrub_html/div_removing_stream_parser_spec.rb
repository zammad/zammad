# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ScrubHtml::DivRemovingStreamParser do
  describe '.parse' do
    describe 'collapsing empty wrapper divs' do
      it 'collapses completely empty nested divs' do
        expect(described_class.parse('<div><div><div></div></div></div>')).to eq('')
      end

      it 'preserves innermost div with text content' do
        expect(described_class.parse('<div><div><div>content</div></div></div>')).to eq('<div>content</div>')
      end

      it 'preserves div with direct text, collapses empty wrappers around nested content' do
        expect(described_class.parse('<div>outer<div><div>inner</div></div></div>'))
          .to eq('<div>outer<div>inner</div></div>')
      end

      it 'preserves multiple content levels' do
        expect(described_class.parse('<div>a<div>b<div>c</div></div></div>'))
          .to eq('<div>a<div>b<div>c</div></div></div>')
      end

      it 'preserves divs with attributes' do
        expect(described_class.parse('<div><div class="wrapper"><div>content</div></div></div>'))
          .to eq('<div class="wrapper"><div>content</div></div>')
      end

      it 'collapses divs without attributes, keeps those with' do
        expect(described_class.parse('<div><div><div id="main"><div>text</div></div></div></div>'))
          .to eq('<div id="main"><div>text</div></div>')
      end
    end

    describe 'preserving non-div elements' do
      it 'marks div as having content when it contains non-div elements' do
        expect(described_class.parse('<div><div><span>text</span></div></div>'))
          .to eq('<div><span>text</span></div>')
      end

      it 'preserves br tags and their parent div' do
        # NOTE: SAX parser outputs </br> for void elements, but this gets cleaned up
        # by the subsequent scrub_html5 call in the actual flow
        expect(described_class.parse('<div><div><br></div></div>'))
          .to eq('<div><br></br></div>')
      end

      it 'preserves complex nested structures' do
        expect(described_class.parse('<div><div><p>paragraph</p><div><span>span</span></div></div></div>'))
          .to eq('<div><p>paragraph</p><div><span>span</span></div></div>')
      end
    end

    describe 'handling whitespace' do
      it 'does not consider whitespace-only content as meaningful for keeping div wrapper' do
        # The div wrappers get collapsed, but the whitespace content is preserved
        expect(described_class.parse('<div><div>   </div></div>')).to eq('   ')
      end

      it 'preserves whitespace around real content' do
        expect(described_class.parse('<div><div>  text  </div></div>')).to eq('<div>  text  </div>')
      end
    end

    describe 'handling comments' do
      it 'drops comments (they get stripped by sanitizers anyway)' do
        expect(described_class.parse('<div><div><!-- comment --></div></div>')).to eq('')
      end

      it 'preserves text content even when comments are present' do
        expect(described_class.parse('<div><div><!-- comment -->text</div></div>'))
          .to eq('<div>text</div>')
      end
    end

    describe 'escaping' do
      it 'escapes special HTML characters in text' do
        expect(described_class.parse('<div><div>&lt;script&gt;</div></div>'))
          .to eq('<div>&lt;script&gt;</div>')
      end

      it 'escapes attribute values' do
        expect(described_class.parse('<div class="a&quot;b"><div>text</div></div>'))
          .to eq('<div class="a&quot;b"><div>text</div></div>')
      end
    end

    describe 'real-world email patterns' do
      it 'collapses Outlook-style deeply nested empty wrappers' do
        html = '<div><div><div><div><div><div><div><div>Message content</div></div></div></div></div></div></div></div>'
        expect(described_class.parse(html)).to eq('<div>Message content</div>')
      end

      it 'preserves mixed content structure from email threads' do
        html = '<div>Reply text<div><div>Original message<div><div><div>Even older message</div></div></div></div></div></div>'
        expect(described_class.parse(html))
          .to eq('<div>Reply text<div>Original message<div>Even older message</div></div></div>')
      end
    end

    describe 'MAX_DIV_DEPTH limit' do
      it 'skips divs beyond MAX_DIV_DEPTH but preserves their content', aggregate_failures: true do
        # Build HTML with MAX_DIV_DEPTH + 5 nested divs, all with content (so none collapse)
        depth = described_class::MAX_DIV_DEPTH + 5
        html = "<div>L1#{'<div>L2' * (depth - 1)}deep content#{'</div>' * depth}"

        result = described_class.parse(html)

        # Content should be preserved
        expect(result).to include('deep content')
          .and include('L1')
          .and include('L2')

        # Should have exactly MAX_DIV_DEPTH opening div tags
        expect(result.scan('<div>').count).to eq(described_class::MAX_DIV_DEPTH)
      end

      it 'content from skipped divs bubbles up to parent', aggregate_failures: true do
        # Create exactly MAX_DIV_DEPTH divs with content, then one more
        divs_at_limit = '<div>x' * described_class::MAX_DIV_DEPTH
        extra_div = '<div>skipped wrapper content</div>'
        closing = '</div>' * described_class::MAX_DIV_DEPTH

        html = "#{divs_at_limit}#{extra_div}#{closing}"
        result = described_class.parse(html)

        # The extra div's content should be in the output (bubbled up)
        expect(result).to include('skipped wrapper content')

        # But only MAX_DIV_DEPTH div wrappers
        expect(result.scan('<div>').count).to eq(described_class::MAX_DIV_DEPTH)
      end
    end
  end
end
