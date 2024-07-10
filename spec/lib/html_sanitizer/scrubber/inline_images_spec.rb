# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Scrubber::InlineImages do
  let(:scrubber) { described_class.new }
  let(:base64)   { 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/...' }

  describe('#scrubber') do
    subject(:actual) { fragment.scrub!(scrubber).to_html }

    let(:fragment) { Loofah.fragment(input) }

    context 'when matching image' do
      let(:input)  { '<img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/...">' }
      let(:target) { %r{<img src="cid:.+?">} }

      it { is_expected.to match target }

      it 'adds attachment to scrubber' do
        actual

        expect(scrubber.attachments_inline).to match_array(include(filename: 'image1.jpeg'))
      end

      context 'when uploaded image is handled' do
        let(:input)  { "<img src='/api/v1/attachments/#{Store.last.id}'>" }
        let(:target) { %r{<img src="cid:.+?">} }

        before do
          form_id = SecureRandom.uuid

          file_name    = 'file1.png'
          file_type    = 'image/png'
          file_content = Base64.strict_encode64('file1')

          UploadCache.new(form_id).tap do |cache|
            cache.add(
              data:          file_content,
              filename:      file_name,
              preferences:   { 'Content-Type' => file_type },
              created_by_id: 1,
            )
          end
        end

        it { is_expected.to match target }

        it 'adds attachment to scrubber' do
          actual

          expect(scrubber.attachments_inline).to match_array(include(filename: 'file1.png'))
        end
      end

      context 'when upload failed' do
        let(:input)  { '<img src="blob:/api/v1/attachments/111">' }
        let(:target) { '' }

        it { is_expected.to match target }
      end
    end

    context 'when not matching image' do
      let(:input)  { '<img src="/image1.jpg">' }
      let(:target) { '<img src="/image1.jpg">' }

      it { is_expected.to eq target }

      it 'adds no attachments to scrubber' do
        actual

        expect(scrubber.attachments_inline).to be_blank
      end
    end
  end

  describe '#inline_image_data' do
    it 'truthy when image' do
      input = base64

      expect(scrubber.send(:inline_image_data, input)).to be_truthy
    end

    it 'falsey when non-jpeg/png' do
      input = 'data:image/gif;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/...'

      expect(scrubber.send(:inline_image_data, input)).to be_falsey
    end

    it 'falsey when URL' do
      input = '/image.jpeg'

      expect(scrubber.send(:inline_image_data, input)).to be_falsey
    end
  end

  describe '#process_inline_image' do
    it 'adds image to attachments' do
      scrubber.send(:process_inline_image, {}, base64)

      first_attachment = scrubber.send(:attachments_inline).first

      expect(first_attachment).to include(filename: 'image1.jpeg')
    end

    it 'adds multiple numbered images to attachments' do
      2.times { scrubber.send(:process_inline_image, {}, base64) }

      filenames = scrubber.send(:attachments_inline).pluck(:filename)

      expect(filenames).to eq %w[image1.jpeg image2.jpeg]
    end

    it 'sets src to cid' do
      node = {}
      allow(scrubber).to receive(:generate_cid).and_return('identifier')

      scrubber.send(:process_inline_image, node, base64)

      expect(node).to include('src' => 'cid:identifier')
    end
  end

  describe '#generate_cid' do
    it 'generates cid' do
      allow(scrubber).to receive(:prefix).and_return(:prefix)

      expect(scrubber.send(:generate_cid)).to start_with('prefix.').and(end_with('zammad.example.com'))
    end
  end

  describe '#parse_inline_image' do
    let(:expected) do
      include(
        data:        be_present,
        filename:    'image1.jpeg',
        preferences: {
          'Content-Type'        => 'image/jpeg',
          'Mime-Type'           => 'image/jpeg',
          'Content-ID'          => :identifier,
          'Content-Disposition' => 'inline',
        }
      )
    end

    it 'returns hash' do
      expect(scrubber.send(:parse_inline_image, base64, :identifier)).to expected
    end
  end
end
