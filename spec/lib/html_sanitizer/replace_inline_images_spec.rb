# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
  end
end
