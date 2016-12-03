# encoding: utf-8
require 'test_helper'

class TranslationTest < ActiveSupport::TestCase

  test 'setup' do
    Translation.reset('de-de')
    Translation.load('de-de')
  end

  test 'basics' do
    tests = [
      {
        locale: 'en',
        string: 'New',
        result: 'New',
      },
      {
        locale: 'en-us',
        string: 'New',
        result: 'New',
      },
      {
        locale: 'de-de',
        string: 'New',
        result: 'Neu',
      },
      {
        locale: 'de-de',
        string: 'not translated - lalala',
        result: 'not translated - lalala',
      },
    ]
    tests.each { |test|
      result = Translation.translate(test[:locale], test[:string])
      assert_equal(result, test[:result], 'verify result')
    }
  end

  test 'own translation tests' do
    locale = 'de-de'

    # check for custom changes
    list = Translation.lang(locale)
    list['list'].each { |item|
      translation = Translation.find_by(source: item[1], locale: locale)
      assert(translation)
      assert_equal(locale, translation.locale)
      assert_equal(translation.target, translation.target_initial)
    }

    # add custom changes
    translation = Translation.find_by(locale: locale, source: 'open')
    assert_equal('offen', translation.target)
    assert_equal('offen', translation.target_initial)
    translation.target = 'offen2'
    translation.save!

    list = Translation.lang(locale)
    list['list'].each { |item|
      translation = Translation.find_by(source: item[1], locale: locale)
      assert(translation)
      assert_equal(locale, translation.locale)
      if translation.source == 'open'
        assert_equal('offen2', translation.target)
        assert_equal('offen', translation.target_initial)
      else
        assert_equal(translation.target, translation.target_initial)
      end
    }

    Translation.load(locale)

    list = Translation.lang(locale)
    list['list'].each { |item|
      translation = Translation.find_by(source: item[1], locale: locale)
      assert(translation)
      assert_equal(locale, translation.locale)
      if translation.source == 'open'
        p translation
        assert_equal('offen2', translation.target)
        assert_equal('offen', translation.target_initial)
      else
        assert_equal(translation.target, translation.target_initial)
      end
    }

    Translation.reset(locale)

    list = Translation.lang(locale)
    list['list'].each { |item|
      translation = Translation.find_by(source: item[1], locale: locale)
      assert(translation)
      assert_equal(locale, translation.locale)
      assert_equal(translation.target, translation.target_initial)
    }

  end

  test 'file based import' do

    # locales
    directory = Rails.root.join('config')
    file = Rails.root.join("#{directory}/locales.yml")
    if File.exist?(file)
      File.delete(file)
    end
    assert_not(File.exist?(file))
    Locale.fetch
    assert(File.exist?(file))

    # translations
    locale = 'de-de'
    directory = Rails.root.join('config/translations')
    if File.directory?(directory)
      FileUtils.rm_rf(directory)
    end
    file = Rails.root.join("#{directory}/#{locale}.yml")
    assert_not(File.exist?(file))
    Translation.fetch(locale)
    assert(File.exist?(file))

  end

end
