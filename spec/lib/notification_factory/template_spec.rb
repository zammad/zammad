# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe NotificationFactory::Template do
  subject(:template) do
    described_class.new(template_string, escape)
  end

  describe '#to_s' do
    context 'for empty input template (incl. whitespace-only)' do
      let(:template_string) { "\#{ }" }

      context 'with escape = true' do
        let(:escape) { true }

        it 'returns an ERB template with the #d helper, and passes escape arg as string' do
          expect(template.to_s).to eq('<%= d "", true %>')
        end
      end

      context 'with escape = false' do
        let(:escape) { false }

        it 'returns an ERB template with the #d helper, and passes escape arg as string' do
          expect(template.to_s).to eq('<%= d "", false %>')
        end
      end
    end

    context 'for input template using #t helper' do
      let(:template_string) { "\#{t('some text')}" }
      let(:escape) { false }

      it 'returns an ERB template with the #t helper, and passes escape arg as string' do
        expect(template.to_s).to eq('<%= t "some text", false %>')
      end

      context 'with double-quotes in argument' do
        let(:template_string) { "\#{t('some \"text\"')}" }

        it 'adds backslash-escaping' do
          expect(template.to_s).to eq('<%= t "some \"text\"", false %>')
        end
      end
    end

    # Regression test for https://github.com/zammad/zammad/issues/385
    context 'with HTML auto-injected by browser' do
      let(:escape) { true }

      context 'for <a> tags wrapped around "ticket.id"' do
        let(:template_string) { <<~'TEMPLATE'.chomp }
          #{<a href="http://ticket.id" title="http://ticket.id" target="_blank">ticket.id</a>}
        TEMPLATE

        it 'strips tag from resulting ERB template' do
          expect(template.to_s).to eq('<%= d "ticket.id", true %>')
        end
      end

      context 'for <a> tags wrapped around "config.fqdn"' do
        let(:template_string) { <<~'TEMPLATE'.chomp }
          #{<a href="http://config.fqdn" title="http://config.fqdn" target="_blank">config.fqdn</a>}
        TEMPLATE

        it 'strips tag from resulting ERB template' do
          expect(template.to_s).to eq('<%= c "fqdn", true %>')
        end
      end

      context 'for <a> tags surrounded by whitespace' do
        let(:template_string) { <<~'TEMPLATE'.chomp }
          #{   <a href="http://ticket.id" title="http://ticket.id" target="_blank">ticket.id  </a>  }
        TEMPLATE

        it 'strips tag and spaces from template' do
          expect(template.to_s).to eq('<%= d "ticket.id", true %>')
        end
      end

      context 'for unpaired <a> tag and trailing whitespace' do
        let(:template_string) { <<~'TEMPLATE'.chomp }
          #{<a href="http://ticket.id" title="http://ticket.id" target="_blank">ticket.id  }
        TEMPLATE

        it 'strips tag and spaces from template' do
          expect(template.to_s).to eq('<%= d "ticket.id", true %>')
        end
      end
    end
  end
end
