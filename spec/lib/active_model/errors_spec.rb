# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ActiveModel::Error, :aggregate_failures do

  context 'with a default rails error available from locale.yml (including interpolation)' do
    let(:error) { User.first.errors.add(:firstname, :equal_to, count: '25') }

    context 'when using the standard error format and the default locale' do
      it 'produces a standard Rails error including the field name' do
        expect(error.message).to eq('must be equal to 25')
        expect(error.full_message).to eq('Firstname must be equal to 25')
      end
    end

    context 'when using a custom error format and a custom locale' do
      let(:custom_translations) { { 'must be equal to %{count}' => 'muss den Wert %{count} haben', 'This field %s' => 'Dieses Feld %<message>s' } } # rubocop:disable Style/FormatStringToken

      it 'produces a custom error NOT including the field name' do
        allow(Translation).to receive(:translate) { |_locale, string| custom_translations[string] || string }
        expect(error.message).to eq('must be equal to 25')
        expect(error.localized_full_message(no_field_name: true, locale: 'de-de')).to eq('Dieses Feld muss den Wert 25 haben')
      end
    end
  end

  context 'with a custom error not available from locale.yml (does not support interpolation)' do
    let(:error) { User.first.errors.add(:firstname, 'is unknown') }

    context 'when using the standard error format and the default locale' do
      it 'produces a standard Rails error including the field name' do
        expect(error.message).to eq('is unknown')
        expect(error.full_message).to eq('Firstname is unknown')
      end
    end

    context 'when using a custom error format and a custom locale' do
      let(:custom_translations) { { 'is unknown' => 'ist unbekannt', 'This field %s' => 'Dieses Feld %{message}' } }

      it 'produces a custom error NOT including the field name' do
        allow(Translation).to receive(:translate) { |_locale, string| custom_translations[string] || string }
        expect(error.message).to eq('is unknown')
        expect(error.localized_full_message(no_field_name: true, locale: 'de-de')).to eq('Dieses Feld ist unbekannt')
      end
    end
  end
end
