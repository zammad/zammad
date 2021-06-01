# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Translation do

  before(:all) do
    described_class.where(locale: 'de-de').destroy_all
    described_class.sync('de-de')
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

    it 'en-us with timestamp as string' do
      expect(described_class.timestamp('en-us', 'Europe/Berlin', '2018-10-10T10:00:00Z0')).to eq('10/10/2018 12:00 (Europe/Berlin)')
    end

    it 'en-us with time object' do
      expect(described_class.timestamp('en-us', 'Europe/Berlin', Time.zone.parse('2018-10-10T10:00:00Z0'))).to eq('10/10/2018 12:00 (Europe/Berlin)')
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

  context 'remote_translation_need_update? tests' do

    it 'translation is still the same' do
      translation = described_class.where(locale: 'de-de', format: 'string').last
      translations = described_class.where(locale: 'de-de').pluck(:id, :locale, :source, :format, :target, :target_initial).to_a
      expect(
        described_class.remote_translation_need_update?(
          {
            'source'         => translation.source,
            'format'         => translation.format,
            'locale'         => translation.locale,
            'target'         => translation.target,
            'target_initial' => translation.target_initial,
          }, translations
        )
      ).to be false
    end

    it 'translation target has locally changed' do
      translation = described_class.where(locale: 'de-de', format: 'string').last
      translation.target = 'some new translation'
      translation.save!
      translations = described_class.where(locale: 'de-de').pluck(:id, :locale, :source, :format, :target, :target_initial).to_a
      expect(
        described_class.remote_translation_need_update?(
          {
            'source'         => translation.source,
            'format'         => translation.format,
            'locale'         => translation.locale,
            'target'         => translation.target,
            'target_initial' => translation.target_initial,
          }, translations
        )
      ).to be false
    end

    it 'translation target has remotely changed' do
      translation = described_class.where(locale: 'de-de', format: 'string').last
      translations = described_class.where(locale: 'de-de').pluck(:id, :locale, :source, :format, :target, :target_initial).to_a
      (result, translation_result) = described_class.remote_translation_need_update?(
        {
          'source'         => translation.source,
          'format'         => translation.format,
          'locale'         => translation.locale,
          'target'         => 'some new translation by remote',
          'target_initial' => 'some new translation by remote',
        }, translations
      )
      expect(result).to be true
      expect(translation_result.attributes).to eq translation.attributes
    end

    it 'translation target has remotely and locally changed' do
      translation = described_class.where(locale: 'de-de', format: 'string').last
      translation.target = 'some new translation'
      translation.save!
      translations = described_class.where(locale: 'de-de').pluck(:id, :locale, :source, :format, :target, :target_initial).to_a
      expect(
        described_class.remote_translation_need_update?(
          {
            'source'         => translation.source,
            'format'         => translation.format,
            'locale'         => translation.locale,
            'target'         => 'some new translation by remote',
            'target_initial' => 'some new translation by remote',
          }, translations
        )
      ).to be false
    end

  end

  context 'custom translation tests' do

    it 'cycle of change and reload translation' do
      locale = 'de-de'

      # check for non existing custom changes
      list = described_class.lang(locale)
      list['list'].each do |item|
        translation = described_class.find_by(source: item[1], locale: locale)
        expect(translation.class).to be(described_class)
        expect(locale).to eq(translation.locale)
        expect(translation.target).to eq(translation.target_initial)
      end

      # add custom changes
      translation = described_class.find_by(locale: locale, source: 'open')
      expect(translation.class).to be(described_class)
      expect(translation.target).to eq('offen')
      expect(translation.target_initial).to eq('offen')
      translation.target = 'offen2'
      translation.save!

      list = described_class.lang(locale)
      list['list'].each do |item|
        translation = described_class.find_by(source: item[1], locale: locale)
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
      described_class.load(locale)
      list = described_class.lang(locale)
      list['list'].each do |item|
        translation = described_class.find_by(source: item[1], locale: locale)
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
        translation = described_class.find_by(source: item[1], locale: locale)
        expect(translation.class).to be(described_class)
        expect(locale).to eq(translation.locale)
        expect(translation.target).to eq(translation.target_initial)
      end
    end

  end

  context 'file based import' do

    it 'check download of locales' do
      version = Version.get
      directory = Rails.root.join('config')
      file = Rails.root.join(directory, "locales-#{version}.yml")
      if File.exist?(file)
        File.delete(file)
      end
      expect(File.exist?(file)).to be false
      Locale.fetch
      expect(File.exist?(file)).to be true
    end

    it 'check download of translations' do
      version = Version.get
      locale = 'de-de'
      directory = Rails.root.join('config/translations')
      if File.directory?(directory)
        FileUtils.rm_rf(directory)
      end
      file = Rails.root.join(directory, "#{locale}-#{version}.yml")
      expect(File.exist?(file)).to be false
      described_class.fetch(locale)
      expect(File.exist?(file)).to be true
    end

  end

  context 'sync duplicate tests' do

    it 'check duplication of entries' do
      described_class.where(locale: 'de-de').destroy_all
      described_class.sync('de-de')
      translation_count = described_class.where(locale: 'de-de').count
      described_class.sync('de-de')
      expect(
        described_class.where(locale: 'de-de').count
      ).to be translation_count
    end

  end

end
