# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FilterProcessor::Match::EndsWith do
  describe '.match' do
    subject(:match) { described_class.match(value: from, match_rule: rules) }

    let(:from) { 'foobar@foo.bar' }

    context 'when the value ends with a matching rule' do
      let(:rules) { ['bar'] }

      it { is_expected.to be(true) }
    end

    context 'with a correct beginning but upper letter matching single rule' do
      let(:rules) { ['Bar'] }

      it { is_expected.to be(true) }
    end

    context 'when the value does not end with any rule' do
      let(:rules) { ['far'] }

      it { is_expected.to be(false) }
    end
  end
end
