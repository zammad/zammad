# encoding: utf-8
require 'test_helper'
 
class TranslationTest < ActiveSupport::TestCase
  test 'translation' do
    tests = [

      # test 1
      {
        :lang   => 'en',
        :string => 'New',
        :result => 'New',
      },

      # test 2
      {
        :lang   => 'de',
        :string => 'New',
        :result => 'Neu',
      },

      # test 3
      {
        :lang   => 'de',
        :string => 'not translated - lalala',
        :result => 'not translated - lalala',
      },
    ]
    tests.each { |test|
      result = Translation.translate( test[:lang], test[:string] )
      assert_equal( result, test[:result], "verify result" )
    }
  end
end