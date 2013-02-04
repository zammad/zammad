# encoding: utf-8
require 'test_helper'

class WorkingTimeTest < ActiveSupport::TestCase
  test 'working time' do
    tests = [

      # test 1
      {
        :start  => '2012-12-17 08:00:00',
        :end    => '2012-12-18 08:00:00',
        :diff   => 480,
        :config => {
          :work_week            => [:mon, :tue, :wed, :thu, :fri ],
          :beginning_of_workday => '8:00 am',
          :end_of_workday       => '6:00 pm',
        },
      },

      # test 2
      {
        :start  => '2012-12-23 08:00:00',
        :end    => '2012-12-24 10:30:42',
        :diff   => 0,
        :config => {
          :work_week            => [:mon, :tue, :wed, :thu, :fri ],
          :beginning_of_workday => '8:00 am',
          :end_of_workday       => '6:00 pm',
          :holidays             => [
            '2012-12-24', '2012-12-25', '2012-12-26'
          ],
        },
      },
    ]
    tests.each { |test|
#      diff = some_method( test[:start], test[:end], test[:config] )
#      assert_equal( diff, test[:diff], 'diff' )
    }
  end
end
