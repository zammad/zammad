# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::DynamicImageSize do
  describe('#sanitize') do
    subject(:sanitized) { described_class.new.sanitize(input) }

    let(:input)  { '<img src="...">' }
    let(:target) { '<img src="..." style="max-width:100%;">' }

    it { expect(sanitized).to eq target }

    context 'when called for base64-encoded inline images' do
      context 'with src attr last' do
        it 'adds max-width: 100% rule to style attr' do
          expect(described_class.new.sanitize(<<~HTML.chomp)).to match(Regexp.new(<<~REGEX.chomp))
            <img style="width: 181px; height: 125px" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/...">
          HTML
            <img style="max-width:100%;width: 181px;max-height: 125px;" src="data:image.+?">
          REGEX
        end
      end

      context 'with src attr first' do
        it 'adds max-width: 100% rule to style attr' do
          expect(described_class.new.sanitize(<<~HTML.chomp)).to match(Regexp.new(<<~REGEX.chomp))
            <img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/..." style="width: 181px; height: 125px" alt="abc">
          HTML
            <img src="data:image.+?" style="max-width:100%;width: 181px;max-height: 125px;" alt="abc">
          REGEX
        end
      end
    end

    context 'when called for image at absolute path' do
      context 'with src attr last' do
        it 'adds max-width: 100% rule to style attr' do
          expect(described_class.new.sanitize(<<~HTML.chomp)).to match(Regexp.new(<<~REGEX.chomp))
            <img src="/some_one.png" style="width: 181px; height: 125px" alt="abc">
          HTML
            <img src="/some_one.png" style="max-width:100%;width: 181px;max-height: 125px;" alt="abc">
          REGEX
        end
      end

      context 'with src attr first' do
        it 'adds max-width: 100% rule to style attr' do
          expect(described_class.new.sanitize(<<~HTML.chomp)).to match(Regexp.new(<<~REGEX.chomp))
            <img src="/some_one.png" alt="abc">
          HTML
            <img src="/some_one.png" alt="abc" style="max-width:100%;">
          REGEX
        end
      end
    end
  end
end
