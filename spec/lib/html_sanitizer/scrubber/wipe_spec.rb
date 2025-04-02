# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Scrubber::Wipe do
  let(:scrubber) { described_class.new }

  describe('#scrubber') do
    subject(:actual) do
      # export with extra options to avoid html indentation
      fragment.scrub!(scrubber)
        .to_html save_with: Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML ^ Nokogiri::XML::Node::SaveOptions::FORMAT
    end

    let(:fragment) { Loofah.fragment(input) }

    context 'when has not allowed tag' do
      let(:input)  { '<not-allowed><b>asd</b></not-allowed>' }
      let(:target) { '<b>asd</b>' }

      it { is_expected.to eq target }
    end

    context 'when has not allowed tag in not allowed' do
      let(:input)  { '<not-allowed><not-allowed>asd</not-allowed></not-allowed>' }
      let(:target) { 'asd' }

      it { is_expected.to eq target }
    end

    context 'when has not allowed tag inside of an allowed tag' do
      let(:input)  { '<div><not-allowed></not-allowed></div>' }
      let(:target) { '<div></div>' }

      it { is_expected.to eq target }
    end

    context 'when insecure source' do
      let(:input)  { '<img src="http://example.org/image.jpg">' }
      let(:target) { '' }

      it { is_expected.to eq target }
    end

    context 'when has not allowed classes' do
      let(:input)  { '<div class="to-be-removed js-signatureMarker">test</div>' }
      let(:target) { '<div class="js-signatureMarker">test</div>' }

      it { is_expected.to eq target }
    end

    context 'when has width and height attributes' do
      let(:input)  { '<img width="100px" height="100px" other="true">' }
      let(:target) { '<img style="width:100px;height:100px;">' }

      it { is_expected.to eq target }
    end

    context 'when has width and max-width attributes' do
      let(:input)  { '<img width="100px" style="max-width: 600px">' }
      let(:target) { '<img style="max-width: 600px;width:100px;">' }

      it { is_expected.to eq target }
    end

    context 'when has not allowed attributes' do
      let(:input)  { '<div width="100px" style="color:#ff0000" other="true">test</div>' }
      let(:target) { '<div style="color:#ff0000;">test</div>' }

      it { is_expected.to eq target }
    end

    context 'when has style' do
      let(:input)  { '<div style="color:white">test</div><div style="color:#ff0000;">test</div>' }
      let(:target) { '<div>test</div><div style="color:#ff0000;">test</div>' }

      it { is_expected.to eq target }
    end

    context 'when has executeable link' do
      let(:input)  { '<img style="width:100%" src="javascript:alert()">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when has an image with a proper link' do
      let(:input)  { '<img style="width:100%" src="https://zammad.org/dummy.png">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end
  end
end
