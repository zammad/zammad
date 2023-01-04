# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ActiveModel::Error, :aggregate_failures do

  let(:error) { User.first.errors.add(:firstname, :blank) }

  context 'when using the standard error format and the default locale' do
    it 'produces a standard Rails error including the field name' do
      expect(error.message).to eq("can't be blank")
      expect(error.full_message).to eq("Firstname can't be blank")
    end
  end

  context 'when using a custom error format and a custom locale' do
    let(:custom_translations) { { "can't be blank" => 'darf nicht leer sein', 'This field %s' => 'Dieses Feld %{message}' } } # rubocop:disable Style/FormatStringToken

    it 'produces a custom error NOT including the field name' do
      allow(Translation).to receive(:translate) { |_locale, string| custom_translations[string] || string }
      expect(error.message).to eq("can't be blank")
      expect(error.localized_full_message(no_field_name: true, locale: 'de-de')).to eq('Dieses Feld darf nicht leer sein')
    end
  end
end
