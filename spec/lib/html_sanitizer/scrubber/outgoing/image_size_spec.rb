# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Scrubber::Outgoing::ImageSize do
  let(:scrubber) { described_class.new }

  describe('#scrubber') do
    subject(:actual) { fragment.scrub!(scrubber).to_html }

    let(:fragment) { Loofah.fragment(input) }

    context 'when no img tag is used' do
      let(:input)  { '<script src="..."></script>' }
      let(:target) { '<script src="..."></script>' }

      it { is_expected.to eq target }
    end

    context 'when no style tag is present' do
      let(:input)  { '<img>' }
      let(:target) { '<img>' }

      it { is_expected.to eq target }
    end

    context 'when width is already present' do
      let(:input)  { '<img width="100">' }
      let(:target) { '<img width="100">' }

      it { is_expected.to eq target }
    end

    context 'when height is already present' do
      let(:input)  { '<img height="100">' }
      let(:target) { '<img height="100">' }

      it { is_expected.to eq target }
    end

    context 'when height and width is already present' do
      let(:input)  { '<img height="25" width="50">' }
      let(:target) { '<img height="25" width="50">' }

      it { is_expected.to eq target }
    end

    context 'when width is present in style' do
      let(:input)  { '<img style="width: 100px">' }
      let(:target) { '<img style="width: 100px" width="100">' }

      it { is_expected.to eq target }

      context 'when width is not a whole number' do
        let(:input)  { '<img style="width: 306.578125px">' }
        let(:target) { '<img style="width: 306.578125px" width="306.578125">' }

        it { is_expected.to eq target }
      end
    end

    context 'when height is present in style' do
      context 'with pixels' do
        let(:input)  { '<img style="height: 100px">' }
        let(:target) { '<img style="height: 100px" height="100">' }

        it { is_expected.to eq target }
      end

      context 'with inches' do
        let(:input)  { '<img style="height: 100in">' }
        let(:target) { '<img style="height: 100in">' }

        it { is_expected.to eq target }
      end
    end

    context 'when height and width are present in style' do
      let(:input)  { '<img style="height: 25px; width: 50px">' }
      let(:target) { '<img style="height: 25px; width: 50px" height="25" width="50">' }

      it { is_expected.to eq target }
    end

    context 'when height and width are present in style and are also set as tags' do
      let(:input)  { '<img style="height: 25px; width: 50px" height="25" width="50">' }
      let(:target) { '<img style="height: 25px; width: 50px" height="25" width="50">' }

      it { is_expected.to eq target }
    end
  end
end
