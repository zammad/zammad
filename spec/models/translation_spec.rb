# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Translation do

  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    described_class.where(locale: 'de-de').destroy_all
    described_class.sync_locale_from_po('de-de')
  end

  context 'default string translations' do

    it 'en with existing word' do
      expect(described_class.translate('en', 'New')).to eq('New')
    end

    it 'en-us with existing word' do
      expect(described_class.translate('en-us', 'New')).to eq('New')
    end

    it 'en with not existing word' do
      expect(described_class.translate('en', 'Some Not Existing Word')).to eq('Some Not Existing Word')
    end

    it 'de-de with existing word' do
      expect(described_class.translate('de-de', 'New')).to eq('Neu')
    end

    it 'de-de with not existing word' do
      expect(described_class.translate('de-de', 'Some Not Existing Word')).to eq('Some Not Existing Word')
    end

    it 'format string with given arguments' do
      expect(described_class.translate('en', 'a %s string', 'given')).to eq('a given string')
    end
  end

  context 'default string translations with fallback' do
    before do
      create(:translation, locale: 'de-de', source: 'dummy message', target: '', target_initial: '')
      described_class.sync_locale_from_po('de-de')
    end

    it 'fallbacks to provided message/string when de-de is empty' do
      expect(described_class.translate('de-de', 'dummy message')).to eq('dummy message')
    end
  end

  context 'when using find_source' do
    it 'de-de with existing title case word' do
      expect(described_class.find_source('de-de', 'New')).to have_attributes(source: 'New', target_initial: 'Neu', target: 'Neu')
    end

    it 'de-de with existing lower case word' do
      expect(described_class.find_source('de-de', 'new')).to have_attributes(source: 'new', target_initial: 'neu', target: 'neu')
    end

    it 'de-de with nonexisting existing source' do
      expect(described_class.find_source('de-de', 'nonexisting-string')).to be_nil
    end
  end

  context 'default timestamp translations' do

    it 'de-de with array' do
      expect(described_class.timestamp('de-de', 'Europe/Berlin', ['some value'])).to eq('["some value"]')
    end

    it 'not_existing with timestamp as string' do
      expect(described_class.timestamp('not_existing', 'Europe/Berlin', '2018-10-10T10:00:00Z0')).to eq('2018-10-10 12:00:00 +0200')
    end

    it 'not_existing with time object' do
      expect(described_class.timestamp('not_existing', 'Europe/Berlin', Time.zone.parse('2018-10-10T10:00:00Z0'))).to eq('2018-10-10 12:00:00 +0200')
    end

    it 'not_existing with invalid timestamp string' do
      expect(described_class.timestamp('not_existing', 'Europe/Berlin', 'something')).to eq('something')
    end

    it 'en-us with invalid time zone' do
      expect(described_class.timestamp('en-us', 'Invalid/TimeZone', '2018-10-10T10:00:00Z0')).to eq(Time.zone.parse('2018-10-10T10:00:00Z0').to_s)
    end

    it 'en-us with timestamp as string (am)' do
      expect(described_class.timestamp('en-us', 'Europe/Berlin', '2018-10-10T01:00:00Z0')).to eq('10/10/2018  3:00 am (Europe/Berlin)')
    end

    it 'en-us with timestamp as string (pm)' do
      expect(described_class.timestamp('en-us', 'Europe/Berlin', '2018-10-10T10:00:00Z0')).to eq('10/10/2018 12:00 pm (Europe/Berlin)')
    end

    it 'en-us with time object (am)' do
      expect(described_class.timestamp('en-us', 'Europe/Berlin', Time.zone.parse('2018-10-10T01:00:00Z0'))).to eq('10/10/2018  3:00 am (Europe/Berlin)')
    end

    it 'en-us with time object (pm)' do
      expect(described_class.timestamp('en-us', 'Europe/Berlin', Time.zone.parse('2018-10-10T10:00:00Z0'))).to eq('10/10/2018 12:00 pm (Europe/Berlin)')
    end

    it 'de-de with timestamp as string' do
      expect(described_class.timestamp('de-de', 'Europe/Berlin', '2018-10-10T10:00:00Z0')).to eq('10.10.2018 12:00 (Europe/Berlin)')
    end

    it 'de-de with time object' do
      expect(described_class.timestamp('de-de', 'Europe/Berlin', Time.zone.parse('2018-10-10T10:00:00Z0'))).to eq('10.10.2018 12:00 (Europe/Berlin)')
    end

  end

  context 'default date translations' do

    it 'de-de with array' do
      expect(described_class.date('de-de', ['some value'])).to eq('["some value"]')
    end

    it 'not_existing with date as string' do
      expect(described_class.date('not_existing', '2018-10-10')).to eq('2018-10-10')
    end

    it 'not_existing with date object' do
      expect(described_class.date('not_existing', Date.parse('2018-10-10'))).to eq('2018-10-10')
    end

    it 'not_existing with invalid data as string' do
      expect(described_class.date('not_existing', 'something')).to eq('something')
    end

    it 'en-us with date as string' do
      expect(described_class.date('en-us', '2018-10-10')).to eq('10/10/2018')
    end

    it 'en-us with date object' do
      expect(described_class.date('en-us', Date.parse('2018-10-10'))).to eq('10/10/2018')
    end

    it 'de-de with date as string' do
      expect(described_class.date('de-de', '2018-10-10')).to eq('10.10.2018')
    end

    it 'de-de with date object' do
      expect(described_class.date('de-de', Date.parse('2018-10-10'))).to eq('10.10.2018')
    end

  end

  context 'custom translation tests' do

    it 'cycle of change and reload translation' do
      locale = 'de-de'

      # check for non existing custom changes
      list = described_class.lang(locale)
      list['list'].each do |item|
        translation = described_class.find_source(locale, item[1])
        expect(translation.class).to be(described_class)
        expect(locale).to eq(translation.locale)
        expect(translation.target).to eq(translation.target_initial)
      end

      # add custom changes
      translation = described_class.find_source(locale, 'open')
      expect(translation.class).to be(described_class)
      expect(translation.target).to eq('offen')
      expect(translation.target_initial).to eq('offen')
      translation.target = 'offen2'
      translation.save!

      list = described_class.lang(locale)
      list['list'].each do |item|
        translation = described_class.find_source(locale, item[1])
        expect(translation.class).to be(described_class)
        expect(locale).to eq(translation.locale)
        if translation.source == 'open'
          expect(translation.target).to eq('offen2')
          expect(translation.target_initial).to eq('offen')
        else
          expect(translation.target).to eq(translation.target_initial)
        end
      end

      # check for existing custom changes after new translations are loaded
      described_class.sync_locale_from_po(locale)
      list = described_class.lang(locale)
      list['list'].each do |item|
        translation = described_class.find_source(locale, item[1])
        expect(translation.class).to be(described_class)
        expect(locale).to eq(translation.locale)
        if translation.source == 'open'
          expect(translation.target).to eq('offen2')
          expect(translation.target_initial).to eq('offen')
        else
          expect(translation.target).to eq(translation.target_initial)
        end
      end

      # reset custom translations and check for non existing custom changes
      described_class.reset(locale)
      list = described_class.lang(locale)
      list['list'].each do |item|
        translation = described_class.find_source(locale, item[1])
        expect(translation.class).to be(described_class)
        expect(locale).to eq(translation.locale)
        expect(translation.target).to eq(translation.target_initial)
      end
    end

  end

  describe 'scope -> sources' do
    it 'returns an source strings' do
      expect(described_class.sources.count).to be_positive
    end
  end

  describe 'scope -> customized' do
    context 'when no customized translations exist' do
      it 'returns an empty array' do
        expect(described_class.customized).to eq([])
      end
    end

    context 'when customized translations exist' do
      before do
        described_class.find_by(locale: 'de-de', source: 'New').update!(target: 'Neu!')
      end

      it 'returns the customized translation' do
        expect(described_class.customized[0].source).to eq('New')
      end
    end

    context 'when only a new customized translation exists' do
      before do
        create(:translation, locale: 'de-de', source: 'A example', target: 'Ein Beispiel')
      end

      it 'returns the customized translation' do
        expect(described_class.customized[0].source).to eq('A example')
      end
    end
  end

  describe 'scope -> not_customized', :aggregate_failures do
    let(:translation_item) { described_class.find_by(locale: 'de-de', source: 'New') }

    context 'when customized items exists' do
      before do
        translation_item.update!(target: 'Neu!')
        create(:translation, locale: 'de-de', source: 'A example', target: 'Ein Beispiel')
      end

      it 'list without customized translations' do
        not_customized = described_class.not_customized.where(locale: 'de-de')

        expect(not_customized).to be_none { |item| item.source == translation_item.source }
        expect(not_customized).to be_none { |item| item.source == 'A example' }
      end
    end
  end

  describe '#reset' do
    context 'when record is not synced from codebase' do
      subject(:translation) { create(:translation, locale: 'de-de', source: 'A example', target: 'Ein Beispiel') }

      it 'no changes for record' do
        expect { translation.reset }.to not_change { translation.reload }
      end
    end

    context 'when record is synced from codebase' do
      subject(:translation) { described_class.find_by(locale: 'de-de', source: 'New') }

      context 'when translation was not customized' do
        it 'no changes for record' do
          expect { translation.reset }.to not_change { translation.reload }
        end
      end

      context 'when translation was customized' do
        before do
          translation.update!(target: 'Neu!')
        end

        it 'resets target to initial' do
          expect { translation.reset }.to change { translation.reload.target }.to(translation.target_initial)
        end
      end
    end
  end

  describe 'source string quality' do
    it 'strings use the unicode ellipsis sign (…) rather than three dots (...)' do
      expect(described_class.sources.where("source LIKE '%...%'").pluck(:source)).to eq([])
    end
  end
end
