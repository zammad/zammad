# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FilterProcessor::Match::EmailRegex do
  describe '.match' do
    subject(:match) { described_class.match(value: from, match_rule: match_rule, check_mode: check_mode) }

    let(:from) { 'foobar@foo.bar' }

    context 'when in normal (error-suppressing) mode (default)' do
      let(:check_mode) { false }

      context 'with empty string' do
        let(:match_rule) { '' }

        it { is_expected.to be(true) }
      end

      context 'with a matching regex' do
        let(:match_rule) { 'foobar@.*' }

        it { is_expected.to be(true) }
      end

      context 'with non-matching regex' do
        let(:match_rule) { 'nagios@.*' }

        it { is_expected.to be(false) }
      end

      context 'with invalid regex (misused ? repeat operator)' do
        let(:match_rule) { '??' }

        it { is_expected.to be(false) }
      end

      context 'with invalid regex (unassociated wild card operator)' do
        let(:match_rule) { '*' }

        it { is_expected.to be(false) }
      end

      context 'with invalid regex (empty char class)' do
        let(:match_rule) { '[]' }

        it { is_expected.to be(false) }
      end

      context 'with a regex with capture groups' do
        context 'with named capture groups' do
          let(:match_rule) { '(?<user>.*)@(?<domain>.*)' }

          context 'when returns true when context is not given' do
            it { is_expected.to be(true) }
          end

          context 'when context is given' do
            subject(:match) { described_class.match(value: from, match_rule:, check_mode:, context:) }

            let(:context)   { { match_data: {} } }

            it { is_expected.to be(true) }

            it 'stores the captures in the context' do
              match

              expect(context[:match_data])
                .to eq({ '1' => 'foobar', '2' => 'foo.bar', 'user' => 'foobar', 'domain' => 'foo.bar' })
            end
          end
        end

        context 'with nameless capture groups' do
          let(:match_rule) { '(.*)@(.*)' }

          context 'when returns true when context is not given' do
            it { is_expected.to be(true) }
          end

          context 'when context is given' do
            subject(:match) { described_class.match(value: from, match_rule:, check_mode:, context:) }

            let(:context)   { { match_data: {} } }

            it { is_expected.to be(true) }

            it 'stores the captures in the context' do
              match

              expect(context[:match_data])
                .to eq({ '1' => 'foobar', '2' => 'foo.bar' })
            end
          end
        end
      end
    end

    context 'when in check (error-raising) mode' do
      let(:check_mode) { true }

      context 'with empty string' do
        let(:match_rule) { '' }

        it { is_expected.to be(true) }
      end

      context 'with matching regex' do
        let(:match_rule) { 'foobar@.*' }

        it { is_expected.to be(true) }
      end

      context 'with non-matching regex' do
        let(:match_rule) { 'nagios@.*' }

        it { is_expected.to be(false) }
      end

      context 'with invalid regex (misused ? repeat operator)' do
        let(:match_rule) { '??' }

        it { expect { match }.to raise_error(<<~ERR.chomp) }
          Can't use regex '??' on 'foobar@foo.bar': target of repeat operator is not specified: /??/i
        ERR
      end

      context 'with invalid regex (unassociated wild card operator)' do
        let(:match_rule) { '*' }

        it { expect { match }.to raise_error(<<~ERR.chomp) }
          Can't use regex '*' on 'foobar@foo.bar': target of repeat operator is not specified: /*/i
        ERR
      end

      context 'with invalid regex (empty char class)' do
        let(:match_rule) { '[]' }

        it { expect { match }.to raise_error(<<~ERR.chomp) }
          Can't use regex '[]' on 'foobar@foo.bar': empty char-class: /[]/i
        ERR
      end
    end
  end
end
