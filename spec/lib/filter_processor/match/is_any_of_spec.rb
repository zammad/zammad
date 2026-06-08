# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FilterProcessor::Match::IsAnyOf do
  describe '.match' do
    subject(:match) { described_class.match(value: subject_value, match_rule: subject_rule) }

    let(:subject_value) { 'Subject1' }

    context 'when the rule includes the exact same subject' do
      let(:subject_rule) { %w[Subject1 Subject2] }

      it { is_expected.to be(true) }
    end

    context 'when the rule does not include the subject' do
      let(:subject_rule) { %w[Subject01 Subject02] }

      it { is_expected.to be(false) }
    end

    context 'when the rule includes a case-insensitive match' do
      let(:subject_rule) { %w[subject1 subject2] }

      it { is_expected.to be(false) }
    end
  end
end
