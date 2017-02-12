require 'rails_helper'

RSpec.describe Translation do

  context 'default translations' do
    Translation.reset('de-de')
    Translation.sync('de-de')

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

  context 'custom translation tests' do
    Translation.where(locale: 'de-de').destroy_all
    Translation.sync('de-de')

    locale = 'de-de'

    it 'cycle of change and reload translation' do

      # check for non existing custom changes
      list = Translation.lang(locale)
      list['list'].each { |item|
        translation = Translation.find_by(source: item[1], locale: locale)
        expect(translation.class).to be(Translation)
        expect(locale).to eq(translation.locale)
        expect(translation.target).to eq(translation.target_initial)
      }

      # add custom changes
      translation = Translation.find_by(locale: locale, source: 'open')
      expect(translation.class).to be(Translation)
      expect(translation.target).to eq('offen')
      expect(translation.target_initial).to eq('offen')
      translation.target = 'offen2'
      translation.save!

      list = Translation.lang(locale)
      list['list'].each { |item|
        translation = Translation.find_by(source: item[1], locale: locale)
        expect(translation.class).to be(Translation)
        expect(locale).to eq(translation.locale)
        if translation.source == 'open'
          expect(translation.target).to eq('offen2')
          expect(translation.target_initial).to eq('offen')
        else
          expect(translation.target).to eq(translation.target_initial)
        end
      }

      # check for existing custom changes after new translations are loaded
      Translation.load(locale)
      list = Translation.lang(locale)
      list['list'].each { |item|
        translation = Translation.find_by(source: item[1], locale: locale)
        expect(translation.class).to be(Translation)
        expect(locale).to eq(translation.locale)
        if translation.source == 'open'
          expect(translation.target).to eq('offen2')
          expect(translation.target_initial).to eq('offen')
        else
          expect(translation.target).to eq(translation.target_initial)
        end
      }

      # reset custom translations and check for non existing custom changes
      Translation.reset(locale)
      list = Translation.lang(locale)
      list['list'].each { |item|
        translation = Translation.find_by(source: item[1], locale: locale)
        expect(translation.class).to be(Translation)
        expect(locale).to eq(translation.locale)
        expect(translation.target).to eq(translation.target_initial)
      }
    end

  end

  context 'file based import' do

    it 'check download of locales' do
      version = Version.get
      directory = Rails.root.join('config')
      file = Rails.root.join("#{directory}/locales-#{version}.yml")
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
      file = Rails.root.join("#{directory}/#{locale}-#{version}.yml")
      expect(File.exist?(file)).to be false
      Translation.fetch(locale)
      expect(File.exist?(file)).to be true
    end

  end

end
