# encoding: utf-8
require 'test_helper'

class TranslationTest < ActiveSupport::TestCase

  Translation.load('de-de')

  test 'translation' do
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
      result = Translation.translate( test[:locale], test[:string] )
      assert_equal( result, test[:result], 'verify result' )
    }
  end
end
