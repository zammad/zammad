# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::ReplaceInlineImages do
  describe('#sanitize') do
    let(:sanitized) { described_class.new.sanitize(input, 'prefix') }
    let(:input)     { '<img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/...">' }
    let(:target)    { %r{<img src="cid:.+?">} }

    it { expect(sanitized.first).to match(target) }
    it { expect(sanitized.last).to include(include(filename: 'image1.jpeg')) }

    context 'when user avatar image exists' do
      let(:user) { create(:user) }
      let(:base64_img)  { 'iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==' }
      let(:decoded_img) { Base64.decode64(base64_img) }
      let(:mime_type)   { 'image/png' }
      let(:avatar) do
        Avatar.add(
          object:        'User',
          o_id:          user.id,
          full:          {
            content:   decoded_img,
            mime_type: mime_type,
          },
          resize:        {
            content:   decoded_img,
            mime_type: mime_type,
          },
          source:        "upload #{Time.zone.now}",
          deletable:     true,
          created_by_id: user.id,
          updated_by_id: user.id,
        )
      end

      let(:input) { "<img src='/api/v1/users/image/#{avatar.store_hash}' width='100' height='100' data-user-avatar='true'>" }

      it { expect(sanitized.first).to match(target) }
      it { expect(sanitized.last).to include(include(filename: 'avatar')) }

      context 'when data-user-avatar is missing' do
        let(:input)  { "<img src='/api/v1/users/image/#{avatar.store_hash}' width='100' height='100'>" }
        let(:target) { "<img src=\"/api/v1/users/image/#{avatar.store_hash}\" width=\"100\" height=\"100\">" }

        it { expect(sanitized.first).to match(target) }
        it { expect(sanitized.last).not_to include(include(filename: 'avatar')) }
      end
    end

    context 'with inline images in different positions', :aggregate_failures do
      let(:body)               { sanitized.first }
      let(:inline_attachments) { sanitized.last }

      context 'when called for image at absolute path' do
        let(:input) { '<img src="/some_one.png" style="width: 181px; height: 125px" alt="abc">' }

        it 'keeps src attr as-is' do
          expect(body).to match(%r{<img src="/some_one.png" style="width: 181px; height: 125px" alt="abc">})
        end

        it 'extracts no attachments' do
          expect(inline_attachments).to be_empty
        end
      end

      context 'when called for base64-encoded inline images' do
        context 'with src attr last' do
          let(:input) { '<img style="width: 181px; height: 125px" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/...">' }

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
          let(:input) { '<img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/..." style="width: 181px; height: 125px" alt="abc">' }

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

        context 'when followed by an incomplete/invalid HTML tag' do
          let(:input) { '<img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/..." style="width: 181px; height: 125px" alt="abc"><invalid what ever' }

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

        context 'when nested in a <div>, mixed with other HTML elements' do
          let(:input) { '<div><img style="width: 181px; height: 125px" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/..."><p>123</p><img style="width: 181px; height: 125px" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/..."></div>' }

          it 'converts embedded image to cid' do
            expect(body).to match(%r{<div><img style="width: 181px; height: 125px" src="cid:.+?"><p>123</p><img style="width: 181px; height: 125px" src="cid:.+?"></div>})
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

      context 'when processing pre elements' do
        let(:input) do
          '<pre><code>apt-get update
Get:1 http://security.ubuntu.com/ubuntu focal-security InRelease [114 kB]
Hit:2 http://de.archive.ubuntu.com/ubuntu focal InRelease
Building dependency tree...</code></pre>'
        end

        it 'does not convert links' do
          expect(body).to eq(input)
        end
      end
    end
  end
end
