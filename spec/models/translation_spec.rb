require 'rails_helper'

RSpec.describe Translation do

  Translation.where(locale: 'de-de').destroy_all
  Translation.sync('de-de')

  context 'default translations' do

    it 'en with existing word' do
      expect(Translation.translate('en', 'New')).to eq('New')
    end

    it 'en-us with existing word' do
      expect(Translation.translate('en-us', 'New')).to eq('New')
    end

    it 'en with not existing word' do
      expect(Translation.translate('en', 'Some Not Existing Word')).to eq('Some Not Existing Word')
    end

    it 'de-de with existing word' do
      expect(Translation.translate('de-de', 'New')).to eq('Neu')
    end

    it 'de-de with existing word' do
      expect(Translation.translate('de-de', 'Some Not Existing Word')).to eq('Some Not Existing Word')
    end

  end

  context 'remote_translation_need_update? tests' do

    it 'translation is still the same' do
      translation = Translation.where(locale: 'de-de', format: 'string').last
      translations = Translation.where(locale: 'de-de').pluck(:id, :locale, :source, :format, :target, :target_initial).to_a
      expect(
        Translation.remote_translation_need_update?(
          {
            'source' => translation.source,
            'format' => translation.format,
            'locale' => translation.locale,
            'target' => translation.target,
            'target_initial' => translation.target_initial,
          }, translations
        )
      ).to be false
    end

    it 'translation target has locally changed' do
      translation = Translation.where(locale: 'de-de', format: 'string').last
      translation.target = 'some new translation'
      translation.save!
      translations = Translation.where(locale: 'de-de').pluck(:id, :locale, :source, :format, :target, :target_initial).to_a
      expect(
        Translation.remote_translation_need_update?(
          {
            'source' => translation.source,
            'format' => translation.format,
            'locale' => translation.locale,
            'target' => translation.target,
            'target_initial' => translation.target_initial,
          }, translations
        )
      ).to be false
    end

    it 'translation target has remotely changed' do
      translation = Translation.where(locale: 'de-de', format: 'string').last
      translations = Translation.where(locale: 'de-de').pluck(:id, :locale, :source, :format, :target, :target_initial).to_a
      (result, translation_result) = Translation.remote_translation_need_update?(
        {
          'source' => translation.source,
          'format' => translation.format,
          'locale' => translation.locale,
          'target' => 'some new translation by remote',
          'target_initial' => 'some new translation by remote',
        }, translations
      )
      expect(result).to be true
      expect(translation_result.attributes).to eq translation.attributes
    end

    it 'translation target has remotely and locally changed' do
      translation = Translation.where(locale: 'de-de', format: 'string').last
      translation.target = 'some new translation'
      translation.save!
      translations = Translation.where(locale: 'de-de').pluck(:id, :locale, :source, :format, :target, :target_initial).to_a
      expect(
        Translation.remote_translation_need_update?(
          {
            'source' => translation.source,
            'format' => translation.format,
            'locale' => translation.locale,
            'target' => 'some new translation by remote',
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
      list = Translation.lang(locale)
      list['list'].each do |item|
        translation = Translation.find_by(source: item[1], locale: locale)
        expect(translation.class).to be(Translation)
        expect(locale).to eq(translation.locale)
        expect(translation.target).to eq(translation.target_initial)
      end

      # add custom changes
      translation = Translation.find_by(locale: locale, source: 'open')
      expect(translation.class).to be(Translation)
      expect(translation.target).to eq('offen')
      expect(translation.target_initial).to eq('offen')
      translation.target = 'offen2'
      translation.save!

      list = Translation.lang(locale)
      list['list'].each do |item|
        translation = Translation.find_by(source: item[1], locale: locale)
        expect(translation.class).to be(Translation)
        expect(locale).to eq(translation.locale)
        if translation.source == 'open'
          expect(translation.target).to eq('offen2')
          expect(translation.target_initial).to eq('offen')
        else
          expect(translation.target).to eq(translation.target_initial)
        end
      end

      # check for existing custom changes after new translations are loaded
      Translation.load(locale)
      list = Translation.lang(locale)
      list['list'].each do |item|
        translation = Translation.find_by(source: item[1], locale: locale)
        expect(translation.class).to be(Translation)
        expect(locale).to eq(translation.locale)
        if translation.source == 'open'
          expect(translation.target).to eq('offen2')
          expect(translation.target_initial).to eq('offen')
        else
          expect(translation.target).to eq(translation.target_initial)
        end
      end

      # reset custom translations and check for non existing custom changes
      Translation.reset(locale)
      list = Translation.lang(locale)
      list['list'].each do |item|
        translation = Translation.find_by(source: item[1], locale: locale)
        expect(translation.class).to be(Translation)
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
      directory = Rails.root.join('config', 'translations')
      if File.directory?(directory)
        FileUtils.rm_rf(directory)
      end
      file = Rails.root.join(directory, "#{locale}-#{version}.yml")
      expect(File.exist?(file)).to be false
      Translation.fetch(locale)
      expect(File.exist?(file)).to be true
    end

  end

  context 'sync duplicate tests' do

    it 'check duplication of entries' do
      Translation.where(locale: 'de-de').destroy_all
      Translation.sync('de-de')
      translation_count = Translation.where(locale: 'de-de').count
      Translation.sync('de-de')
      expect(
        Translation.where(locale: 'de-de').count
      ).to be translation_count
    end

  end

end
