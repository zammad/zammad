# encoding: utf-8
require 'test_helper'
 
class TranslationTest < ActiveSupport::TestCase
  test 'translation' do
    tests = [

      # test 1
      {
        locale: 'en',
        string: 'New',
        result: 'New',
      },

      # test 2
      {
        locale: 'de-de',
        string: 'New',
        result: 'Neu',
      },

      # test 3
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