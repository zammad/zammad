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

      # test 5
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

      # test 6
      {
        :start  => '2013-02-28 17:00:00',
        :end    => '2013-03-08 23:59:59',
        :diff   => 3660,
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

      # test 7
      {
        :start  => '2012-02-28 17:00:00',
        :end    => '2013-03-08 23:59:59',
        :diff   => 160_860,
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

      # test 8
      {
        :start  => '2013-02-28 17:01:00',
        :end    => '2013-02-28 18:10:59',
        :diff   => 61,
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

      # test 9
      {
        :start  => '2013-02-28 18:01:00',
        :end    => '2013-02-28 18:10:59',
        :diff   => 0,
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

      # test 10 / summertime
      {
        :start  => '2013-02-28 18:01:00',
        :end    => '2013-02-28 18:10:59',
        :diff   => 0,
        :timezone => 'Europe/Berlin',
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

      # test 11 / summertime
      {
        :start  => '2013-02-28 17:01:00',
        :end    => '2013-02-28 17:10:59',
        :diff   => 0,
        :timezone => 'Europe/Berlin',
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

      # test 12 / wintertime
      {
        :start  => '2013-08-29 17:01:00',
        :end    => '2013-08-29 17:10:59',
        :diff   => 0,
        :timezone => 'Europe/Berlin',
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

      # test 13 / summertime
      {
        :start  => '2013-02-28 16:01:00',
        :end    => '2013-02-28 16:10:59',
        :diff   => 10,
        :timezone => 'Europe/Berlin',
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

      # test 14 / wintertime
      {
        :start  => '2013-08-29 16:01:00',
        :end    => '2013-08-29 16:10:59',
        :diff   => 0,
        :timezone => 'Europe/Berlin',
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

      # test 15
      {
        :start  => '2013-08-29 16:01:00',
        :end    => '2013-08-29 16:10:59',
        :diff   => 10,
      },
    ]
    tests.each { |test|
      diff = TimeCalculation.business_time_diff( test[:start], test[:end], test[:config], test[:timezone] )
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

      # test 3
      {
        :start     => '2012-12-17 08:00:00',
        :dest_time => '2012-12-18 18:00:00',
        :diff      => 1200,
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

      # test 4
      {
        :start     => '2012-12-17 08:00:00',
        :dest_time => '2012-12-19 08:30:00',
        :diff      => 1230,
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

      # test 5
      {
        :start     => '2012-12-17 08:00:00',
        :dest_time => '2012-12-21 18:00:00',
        :diff      => 3000,
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


      # test 6
      {
        :start     => '2012-12-17 08:00:00',
        :dest_time => '2012-12-24 08:05:00',
        :diff      => 3005,
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

      # test 7
      {
        :start     => '2012-12-17 08:00:00',
        :dest_time => '2012-12-31 08:05:00',
        :diff      => 6005,
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

      # test 8
      {
        :start     => '2012-12-17 08:00:00',
        :dest_time => '2012-12-31 13:30:00',
        :diff      => 6330,
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

      # test 9
      {
        :start     => '2013-04-12 21:20:15',
        :dest_time => '2013-04-15 10:00:00',
        :diff      => 120,
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

      # test 11 / summertime 7am-5pm
      {
        :start     => '2013-03-08 21:20:15',
        :dest_time => '2013-03-11 09:00:00',
        :diff      => 120,
        :timezone  => 'Europe/Berlin',
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

      # test 12 / wintertime 6am-4pm
      {
        :start     => '2013-09-06 21:20:15',
        :dest_time => '2013-09-09 08:00:00',
        :diff      => 120,
        :timezone  => 'Europe/Berlin',
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

      # test 13 / wintertime - 7am-4pm
      {
        :start     => '2013-10-21 06:30:00',
        :dest_time => '2013-10-21 09:00:00',
        :diff      => 120,
        :timezone  => 'Europe/Berlin',
        :config    => {
          'Mon'                  => true,
          'Tue'                  => true,
          'Wed'                  => true,
          'Thu'                  => true,
          'Fri'                  => true,
          'beginning_of_workday' => '9:00 am',
          'end_of_workday'       => '6:00 pm',
        },
      },

      # test 14 / wintertime - 7am-4pm
      {
        :start     => '2013-10-21 04:34:15',
        :dest_time => '2013-10-21 09:00:00',
        :diff      => 120,
        :timezone  => 'Europe/Berlin',
        :config    => {
          'Mon'                  => true,
          'Tue'                  => true,
          'Wed'                  => true,
          'Thu'                  => true,
          'Fri'                  => true,
          'beginning_of_workday' => '9:00 am',
          'end_of_workday'       => '6:00 pm',
        },
      },

      # test 15 / wintertime - 7am-4pm
      {
        :start     => '2013-10-20 22:34:15',
        :dest_time => '2013-10-21 09:00:00',
        :diff      => 120,
        :timezone  => 'Europe/Berlin',
        :config    => {
          'Mon'                  => true,
          'Tue'                  => true,
          'Wed'                  => true,
          'Thu'                  => true,
          'Fri'                  => true,
          'beginning_of_workday' => '9:00 am',
          'end_of_workday'       => '6:00 pm',
        },
      },

      # test 16 / wintertime - 7am-4pm
      {
        :start     => '2013-10-21 07:00:15',
        :dest_time => '2013-10-21 09:00:15',
        :diff      => 120,
        :timezone  => 'Europe/Berlin',
        :config    => {
          'Mon'                  => true,
          'Tue'                  => true,
          'Wed'                  => true,
          'Thu'                  => true,
          'Fri'                  => true,
          'beginning_of_workday' => '9:00 am',
          'end_of_workday'       => '6:00 pm',
        },
      },

      # test 17
      {
        :start     => '2013-10-21 04:01:00',
        :dest_time => '2013-10-21 06:00:00',
        :diff      => 119,
      },

      # test 18
      {
        :start     => '2013-10-21 04:01:00',
        :dest_time => '2013-10-21 04:01:00',
        :diff      => 0,
      },

      # test 19
      {
        :start     => '2013-04-12 21:20:15',
        :dest_time => '2013-04-12 21:20:15',
        :diff      => 0,
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

      # test 20
      {
        :start     => '2013-04-12 11:20:15',
        :dest_time => '2013-04-12 11:21:15',
        :diff      => 1,
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
      dest_time = TimeCalculation.dest_time( test[:start] + ' UTC', test[:diff], test[:config], test[:timezone] )
      assert_equal( dest_time.gmtime, Time.parse( test[:dest_time] + ' UTC' ), "dest time - #{test[:dest_time]}" )
    }
  end

end
