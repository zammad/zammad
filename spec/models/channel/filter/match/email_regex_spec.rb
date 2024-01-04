# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::Match::EmailRegex do
  describe '.match' do
    subject(:match) { described_class.match(value: from, match_rule: sender, check_mode: check_mode) }

    let(:from) { 'foobar@foo.bar' }

    context 'in normal (error-suppressing) mode (default)' do
      let(:check_mode) { false }

      context 'with empty string' do
        let(:sender) { '' }

        it { is_expected.to be(true) }
      end

      context 'and matching regex' do
        let(:sender) { 'foobar@.*' }

        it { is_expected.to be(true) }
      end

      context 'and non-matching regex' do
        let(:sender) { 'nagios@.*' }

        it { is_expected.to be(false) }
      end

      context 'and invalid regex (misused ? repeat operator)' do
        let(:sender) { '??' }

        it { is_expected.to be(false) }
      end

      context 'and invalid regex (unassociated wild card operator)' do
        let(:sender) { '*' }

        it { is_expected.to be(false) }
      end

      context 'and invalid regex (empty char class)' do
        let(:sender) { '[]' }

        it { is_expected.to be(false) }
      end
    end

    context 'in check (error-raising) mode' do
      let(:check_mode) { true }

      context 'with empty string' do
        let(:sender) { '' }

        it { is_expected.to be(true) }
      end

      context 'and matching regex' do
        let(:sender) { 'foobar@.*' }

        it { is_expected.to be(true) }
      end

      context 'and non-matching regex' do
        let(:sender) { 'nagios@.*' }

        it { is_expected.to be(false) }
      end

      context 'and invalid regex (misused ? repeat operator)' do
        let(:sender) { '??' }

        it { expect { match }.to raise_error(<<~ERR.chomp) }
          Can't use regex '??' on 'foobar@foo.bar': target of repeat operator is not specified: /??/i
        ERR
      end

      context 'and invalid regex (unassociated wild card operator)' do
        let(:sender) { '*' }

        it { expect { match }.to raise_error(<<~ERR.chomp) }
          Can't use regex '*' on 'foobar@foo.bar': target of repeat operator is not specified: /*/i
        ERR
      end

      context 'and invalid regex (empty char class)' do
        let(:sender) { '[]' }

        it { expect { match }.to raise_error(<<~ERR.chomp) }
          Can't use regex '[]' on 'foobar@foo.bar': empty char-class: /[]/i
        ERR
      end
    end
  end
end
