# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HtmlSanitizer do
  describe '.replace_inline_images' do
    let(:body) { described_class.replace_inline_images(html).first }
    let(:inline_attachments) { described_class.replace_inline_images(html).last }

    context 'for image at absolute path' do
      let(:html) { '<img src="/some_one.png" style="width: 181px; height: 125px" alt="abc">' }

      it 'keeps src attr as-is' do
        expect(body).to match(%r{<img src="/some_one.png" style="width: 181px; height: 125px" alt="abc">})
      end

      it 'extracts no attachments' do
        expect(inline_attachments).to be_empty
      end
    end

    context 'for base64-encoded inline images' do
      context 'with src attr last' do
        let(:html) { '<img style="width: 181px; height: 125px" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/...">' }

        it 'converts embedded image to cid' do
          expect(body).to match(%r{<img style="width: 181px; height: 125px" src="cid:.+?">})
        end

        it 'extracts one attachment' do
          expect(inline_attachments).to be_one
        end

        it 'sets filename to image1.jpeg' do
          expect(inline_attachments.first[:filename]).to eq('image1.jpeg')
        end

        it 'sets Content-Type to image/jpeg' do
          expect(inline_attachments.first[:preferences]['Content-Type']).to eq('image/jpeg')
        end

        it 'sets Content-ID based on Zammad fqdn' do
          expect(inline_attachments.first[:preferences]['Content-ID']).to match(%r{@#{Setting.get('fqdn')}})
        end

        it 'sets Content-Disposition to inline' do
          expect(inline_attachments.first[:preferences]['Content-Disposition']).to eq('inline')
        end
      end

      context 'with src attr first' do
        let(:html) { '<img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/..." style="width: 181px; height: 125px" alt="abc">' }

        it 'converts embedded image to cid' do
          expect(body).to match(%r{<img src="cid:.+?" style="width: 181px; height: 125px" alt="abc">})
        end

        it 'extracts one attachment' do
          expect(inline_attachments).to be_one
        end

        it 'sets filename to image1.jpeg' do
          expect(inline_attachments.first[:filename]).to eq('image1.jpeg')
        end

        it 'sets Content-Type to image/jpeg' do
          expect(inline_attachments.first[:preferences]['Content-Type']).to eq('image/jpeg')
        end

        it 'sets Content-ID based on Zammad fqdn' do
          expect(inline_attachments.first[:preferences]['Content-ID']).to match(%r{@#{Setting.get('fqdn')}})
        end

        it 'sets Content-Disposition to inline' do
          expect(inline_attachments.first[:preferences]['Content-Disposition']).to eq('inline')
        end
      end

      context 'followed by an incomplete/invalid HTML tag' do
        let(:html) { '<img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/..." style="width: 181px; height: 125px" alt="abc"><invalid what ever' }

        it 'converts embedded image to cid' do
          expect(body).to match(%r{<img src="cid:.+?" style="width: 181px; height: 125px" alt="abc">})
        end

        it 'extracts one attachment' do
          expect(inline_attachments).to be_one
        end

        it 'sets filename to image1.jpeg' do
          expect(inline_attachments.first[:filename]).to eq('image1.jpeg')
        end

        it 'sets Content-Type to image/jpeg' do
          expect(inline_attachments.first[:preferences]['Content-Type']).to eq('image/jpeg')
        end

        it 'sets Content-ID based on Zammad fqdn' do
          expect(inline_attachments.first[:preferences]['Content-ID']).to match(%r{@#{Setting.get('fqdn')}})
        end

        it 'sets Content-Disposition to inline' do
          expect(inline_attachments.first[:preferences]['Content-Disposition']).to eq('inline')
        end
      end

      context 'nested in a <div>, mixed with other HTML elements' do
        let(:html) { '<div><img style="width: 181px; height: 125px" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/..."><p>123</p><img style="width: 181px; height: 125px" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/..."></div>' }

        it 'converts embedded image to cid' do
          expect(body).to match(%r{<div>\s+<img style="width: 181px; height: 125px" src="cid:.+?"><p>123</p>\s+<img style="width: 181px; height: 125px" src="cid:.+?">\s+</div>})
        end

        it 'extracts two attachments' do
          expect(inline_attachments.length).to be(2)
        end

        it 'sets filenames sequentially (as imageN.jpeg)' do
          expect(inline_attachments.first[:filename]).to eq('image1.jpeg')
          expect(inline_attachments.second[:filename]).to eq('image2.jpeg')
        end

        it 'sets Content-Types to image/jpeg' do
          expect(inline_attachments.first[:preferences]['Content-Type']).to eq('image/jpeg')
          expect(inline_attachments.second[:preferences]['Content-Type']).to eq('image/jpeg')
        end

        it 'sets Content-IDs based on Zammad fqdn' do
          expect(inline_attachments.first[:preferences]['Content-ID']).to match(%r{@#{Setting.get('fqdn')}})
          expect(inline_attachments.second[:preferences]['Content-ID']).to match(%r{@#{Setting.get('fqdn')}})
        end

        it 'sets Content-Dispositions to inline' do
          expect(inline_attachments.first[:preferences]['Content-Disposition']).to eq('inline')
          expect(inline_attachments.second[:preferences]['Content-Disposition']).to eq('inline')
        end
      end
    end
  end

  describe '.dynamic_image_size' do
    context 'for image at absolute path' do
      context 'with src attr last' do
        it 'add max-width: 100% rule to style attr' do
          expect(described_class.dynamic_image_size(<<~HTML.chomp)).to match(Regexp.new(<<~REGEX.chomp))
            <img style="width: 181px; height: 125px" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/...">
          HTML
            <img style="max-width:100%;width: 181px;max-height: 125px;" src="data:image.+?">
          REGEX
        end
      end

      context 'with src attr first' do
        it 'add max-width: 100% rule to style attr' do
          expect(described_class.dynamic_image_size(<<~HTML.chomp)).to match(Regexp.new(<<~REGEX.chomp))
            <img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/..." style="width: 181px; height: 125px" alt="abc">
          HTML
            <img src="data:image.+?" style="max-width:100%;width: 181px;max-height: 125px;" alt="abc">
          REGEX
        end
      end
    end

    context 'for base64-encoded inline images' do
      context 'with src attr last' do
        it 'add max-width: 100% rule to style attr' do
          expect(described_class.dynamic_image_size(<<~HTML.chomp)).to match(Regexp.new(<<~REGEX.chomp))
            <img src="/some_one.png" style="width: 181px; height: 125px" alt="abc">
          HTML
            <img src="/some_one.png" style="max-width:100%;width: 181px;max-height: 125px;" alt="abc">
          REGEX
        end
      end

      context 'with src attr first' do
        it 'add max-width: 100% rule to style attr' do
          expect(described_class.dynamic_image_size(<<~HTML.chomp)).to match(Regexp.new(<<~REGEX.chomp))
            <img src="/some_one.png" alt="abc">
          HTML
            <img src="/some_one.png" alt="abc" style="max-width:100%;">
          REGEX
        end
      end
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

    context 'with href links that contain square brackets' do
      it 'correctly URL encodes them' do
        expect(described_class.strict(+'<a href="https://example.com/?foo=bar&baz[x]=y">example</a>', true))
          .to eq('<a href="https://example.com/?foo=bar&amp;baz%5Bx%5D=y" rel="nofollow noreferrer noopener" target="_blank" title="https://example.com/?foo=bar&amp;baz%5Bx%5D=y">example</a>')
      end
    end

    context 'with href links that contain http urls' do
      it 'correctly URL encodes them' do
        expect(described_class.strict(+'<a href="https://example.com/?foo=https%3A%2F%2Fexample.com%3Flala%3A123">example</a>', true))
          .to eq('<a href="https://example.com/?foo=https%3A%2F%2Fexample.com%3Flala%3A123" rel="nofollow noreferrer noopener" target="_blank" title="https://example.com/?foo=https%3A%2F%2Fexample.com%3Flala%3A123">example</a>')
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
