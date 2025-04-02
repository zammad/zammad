# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::Match::Contains do
  describe '.match' do
    subject(:match) { described_class.match(value: from, match_rule: sender) }

    let(:from) { 'foobar@foo.bar' }

    context 'with exact match' do
      let(:sender) { 'foobar@foo.bar' }

      it { is_expected.to be(true) }
    end

    context 'with wildcard *' do
      let(:sender) { '*' }

      it { is_expected.to be(true) }
    end

    context 'with empty string' do
      let(:sender) { '' }

      it { is_expected.to be(true) }
    end
  end
end
