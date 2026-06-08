# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FilterProcessor::Match::StartsWith do
  describe '.match' do
    subject(:match) { described_class.match(value: from, match_rule: rules) }

    let(:from) { 'foobar@foo.bar' }

    context 'when the value starts with a matching rule' do
      let(:rules) { ['foo'] }

      it { is_expected.to be(true) }
    end

    context 'when the value starts with a matching rule in a different case' do
      let(:rules) { ['Foo'] }

      it { is_expected.to be(true) }
    end

    context 'when the value does not start with any rule' do
      let(:rules) { ['doo'] }

      it { is_expected.to be(false) }
    end
  end
end
