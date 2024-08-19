# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Locale, type: :model do
  describe '.default' do
    context 'with default locale' do
      before { Setting.set('locale_default', 'foo') }

      it 'returns the system-wide default locale' do
        expect(described_class.default).to eq('foo')
      end
    end

    context 'without default locale' do
      before { Setting.set('locale_default', nil) }

      it 'returns en-us' do
        expect(described_class.default).to eq('en-us')
      end
    end
  end

  describe '.sync()' do
    context 'when importing locales' do
      before do
        described_class.delete_all
        described_class.sync
      end

      it 'imports many locales locales' do
        expect(described_class.count).to be > 40
      end

      it 'imports locale data correctly' do
        expect(described_class.find_by(locale: 'de-de')).to have_attributes(locale: 'de-de', alias: 'de', name: 'Deutsch', dir: 'ltr', active: true)
      end
    end
  end

  # Ensure valid date/time format strings. Since not all translations are imported in CI,
  #  we read the values from the po file directly.
  # See also https://github.com/zammad/zammad/issues/5223
  describe 'locale validity' do
    before do
      described_class.sync
    end

    def string_from_po(locale, msgid)
      po = Rails.root.join("i18n/zammad.#{locale.locale}.po").read
      po.scan(%r{msgid "#{msgid}"\nmsgstr "([^"]+)"}).first.first
    end

    matcher :have_valid_date_format_string do
      match do
        string_from_po(actual, 'FORMAT_DATE').match(%r{^[ymd./ -]+$})
      end

      failure_message do
        "Locale #{actual.locale} has an invalid value for FORMAT_DATE: #{string_from_po(actual, 'FORMAT_DATE')}"
      end
    end

    matcher :have_valid_datetime_format_string do
      match do
        string_from_po(actual, 'FORMAT_DATETIME').match(%r{^[ymdHMSlP:./ -]+$})
      end

      failure_message do
        "Locale #{actual.locale} has an invalid value for FORMAT_DATETIME: #{string_from_po(actual, 'FORMAT_DATETIME')}"
      end
    end

    it 'has locales with valid format strings', :aggregate_failures do
      skip_locales = %w[en-us sr-latn-rs].freeze
      described_class.all.each do |locale|
        next if skip_locales.include?(locale.locale)

        expect(locale).to have_valid_date_format_string
        expect(locale).to have_valid_datetime_format_string
      end
    end
  end
end
