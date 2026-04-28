# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class Scrub1 < Loofah::Scrubber
  def scrub(node)
    node.name = 'scrub1_modified' if node.name == 'scrubit'
    node
  end
end

class Scrub2 < Loofah::Scrubber
  def scrub(node)
    node.name = 'scrub2_modified' if node.name == 'scrub1_modified'
    node
  end
end

RSpec.describe ScrubHtml do
  describe '#scrub!' do
    let(:scrubbers)          { [Scrub1.new, Scrub2.new] }
    let(:input_html)         { '<scrubit>Content</scrubit>' }
    let(:nested_elem)        { 'div' }
    let(:deeply_nested_html) { ("<#{nested_elem}>" * nesting_level) + input_html + ("</#{nested_elem}>" * nesting_level) }

    it 'runs scrubs in a given order' do
      scrubbed = described_class
        .new(input_html, scrubbers)
        .scrub!
        .to_html

      expect(scrubbed).to eq('<scrub2_modified>Content</scrub2_modified>')
    end

    it 'respects chunk type' do
      scrubbed = described_class
        .new(input_html, scrubbers, chunk: :document)
        .scrub!
        .to_html

      # In document mode, Loofah wraps content in <html><head></head><body>...</body></html>
      expect(scrubbed).to eq('<html><head></head><body><scrub2_modified>Content</scrub2_modified></body></html>')
    end

    context 'with non-UTF8 HTML document' do
      let(:input_html) { '<scrubit>Ačiū</scrubit>' }
      let(:html_document) do
        "<html><head><meta charset=\"windows-1257\"></head><body>#{input_html}</body></html>"
      end

      it 'keeps encoding intact' do
        scrubbed = described_class
          .new(html_document, scrubbers, chunk: :document)
          .scrub!
          .to_html

        expect(scrubbed).to eq('<html><head><meta charset="windows-1257"></head><body><scrub2_modified>Ačiū</scrub2_modified></body></html>')
      end
    end

    context 'with shallow nesting' do
      let(:nesting_level) { 10 }

      it 'keeps DIVs intact' do
        scrubbed = described_class
          .new(deeply_nested_html, scrubbers)
          .scrub!
          .to_html

        expect(scrubbed).to eq('<div><div><div><div><div><div><div><div><div><div><scrub2_modified>Content</scrub2_modified></div></div></div></div></div></div></div></div></div></div>')
      end
    end

    context 'with deep nesting' do
      let(:nesting_level) { 500 }

      it 'rescrubs on depth limit errors' do
        scrubbed = described_class
          .new(deeply_nested_html, scrubbers)
          .scrub!
          .to_html

        expect(scrubbed).to eq('<div><scrub2_modified>Content</scrub2_modified></div>')
      end

      it 'respects chunk type on rescrub' do
        scrubbed = described_class
          .new(deeply_nested_html, scrubbers, chunk: :document)
          .scrub!
          .to_html

        expect(scrubbed).to eq('<html><head></head><body><div><scrub2_modified>Content</scrub2_modified></div></body></html>')
      end

      # NOTE: ScrubHtml receives UTF-8 string, but HTML itself may contain different charset
      # Then libxml2 gets confused and re-encodes it breaking characters
      # This test ensures encoding is preserved correctly
      context 'with non-UTF8 HTML document' do
        let(:input_html) { '<scrubit>Ačiū</scrubit>' }
        let(:html_document) do
          "<html><head><meta charset=\"windows-1257\"></head><body>#{deeply_nested_html}</body></html>"
        end

        it 'keeps encoding intact' do
          scrubbed = described_class
            .new(html_document, scrubbers, chunk: :document)
            .scrub!
            .to_html

          expect(scrubbed).to eq('<html><head><meta charset="windows-1257"></head><body><div><scrub2_modified>Ačiū</scrub2_modified></div></body></html>')
        end
      end

      # https://github.com/zammad/zammad/issues/6054
      context 'with charset that does not cover all characters in the document' do
        let(:input_html) { '<scrubit>Hello</scrubit>' }
        let(:html_document) do
          # U+2013 (en-dash) is valid UTF-8 but undefined in GB2312
          "<html><head><meta charset=\"gb2312\"></head><body>–#{deeply_nested_html}</body></html>"
        end

        it 'does not raise an encoding error' do
          expect do
            described_class
              .new(html_document, scrubbers, chunk: :document)
              .scrub!
          end.not_to raise_error
        end
      end
    end

    context 'when non-divs are nested' do
      let(:nesting_level) { 500 }
      let(:nested_elem)   { 'nondiv' }

      it 'bubbles up depth limit error' do
        expect do
          described_class
            .new(deeply_nested_html, scrubbers)
            .scrub!
            .to_html
        end.to raise_error(ArgumentError, 'Document tree depth limit exceeded')
      end
    end
  end
end
