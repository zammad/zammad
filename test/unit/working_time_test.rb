# encoding: utf-8
require 'test_helper'
require 'time_calculation'

class WorkingTimeTest < ActiveSupport::TestCase
  test 'working time' do
    tests = [

      # test 1
      {
        :start  => '2012-12-17 08:00:00',
        :end    => '2012-12-18 08:00:00',
        :diff   => 600,
        :config => {
          'Mon'                  => true,
          'Tue'                  => true,
          'Wed'                  => true,
          'Thu'                  => true,
          'Fri'                  => true,
          'beginning_of_workday' => '8:00 am',
          'end_of_workday'       => '6:00 pm',
        },
      },

      # test 2
      {
        :start  => '2012-12-17 08:00:00',
        :end    => '2012-12-17 09:00:00',
        :diff   => 60,
        :config => {
          'Mon'                  => true,
          'Tue'                  => true,
          'Wed'                  => true,
          'Thu'                  => true,
          'Fri'                  => true,
          'beginning_of_workday' => '8:00 am',
          'end_of_workday'       => '6:00 pm',
        },
      },

      # test 3
      {
        :start  => '2012-12-17 08:00:00',
        :end    => '2012-12-17 08:15:00',
        :diff   => 15,
        :config => {
          'Mon'                  => true,
          'Tue'                  => true,
          'Wed'                  => true,
          'Thu'                  => true,
          'Fri'                  => true,
          'beginning_of_workday' => '8:00 am',
          'end_of_workday'       => '6:00 pm',
        },
      },

      # test 4
      {
        :start  => '2012-12-23 08:00:00',
        :end    => '2012-12-27 10:30:42',
#        :diff   => 0,
        :diff   => 151,
        :config => {
          'Mon'                  => true,
          'Tue'                  => true,
          'Wed'                  => true,
          'Thu'                  => true,
          'Fri'                  => true,
          'beginning_of_workday' => '8:00 am',
          'end_of_workday'       => '6:00 pm',
          'holidays'             => [
            '2012-12-24', '2012-12-25', '2012-12-26'
          ],
        },
      },
      {
        :start  => '2013-02-28 17:00:00',
        :end    => '2013-02-28 23:59:59',
        :diff   => 60,
        :config => {
          'Mon'                  => true,
          'Tue'                  => true,
          'Wed'                  => true,
          'Thu'                  => true,
          'Fri'                  => true,
          'beginning_of_workday' => '8:00 am',
          'end_of_workday'       => '6:00 pm',
        },
      },
    ]
    tests.each { |test|
      TimeCalculation.config( test[:config] )
      diff = TimeCalculation.business_time_diff( test[:start], test[:end] )
      assert_equal( diff, test[:diff], 'diff' )
    }
  end

  test 'dest time' do
    tests = [

      # test 1
      {
        :start     => '2012-12-17 08:00:00',
        :dest_time => '2012-12-17 18:00:00',
        :diff      => 600,
        :config    => {
          'Mon'                  => true,
          'Tue'                  => true,
          'Wed'                  => true,
          'Thu'                  => true,
          'Fri'                  => true,
          'beginning_of_workday' => '8:00 am',
          'end_of_workday'       => '6:00 pm',
        },
      },

      # test 2
      {
        :start     => '2012-12-17 08:00:00',
        :dest_time => '2012-12-18 08:30:00',
        :diff      => 630,
        :config    => {
          'Mon'                  => true,
          'Tue'                  => true,
          'Wed'                  => true,
          'Thu'                  => true,
          'Fri'                  => true,
          'beginning_of_workday' => '8:00 am',
          'end_of_workday'       => '6:00 pm',
        },
      },
    ]
    tests.each { |test|
      TimeCalculation.config( test[:config] )
      dest_time = TimeCalculation.dest_time( test[:start] + ' UTC', test[:diff] )
      assert_equal( dest_time.gmtime, Time.parse( test[:dest_time] + ' UTC' ), 'dest time' )
    }
  end

end
