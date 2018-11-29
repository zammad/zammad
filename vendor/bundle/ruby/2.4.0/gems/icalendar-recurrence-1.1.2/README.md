# iCalendar Recurrence [![Build Status](https://travis-ci.org/icalendar/icalendar-recurrence.svg?branch=master)](https://travis-ci.org/icalendar/icalendar-recurrence) [![Code Climate](https://codeclimate.com/github/icalendar/icalendar-recurrence.png)](https://codeclimate.com/github/icalendar/icalendar-recurrence) 

Adds event recurrence to the [icalendar gem](https://github.com/icalendar/icalendar). This is helpful in cases where you'd like to parse an ICS and generate a series of event occurrences.

## Install

_Note: Works with 2.0.0beta.1 (or newer) icalendar gem. If you're using icalendar <=1.5.4, take a look at the [new code](https://github.com/icalendar/icalendar/tree/2.0beta) before you switch over._

```ruby
gem "icalendar-recurrence"
```

and run `bundle install` from your shell.

## Usage

### Show occurrences of event between dates

```ruby
require 'date' # for parse method
require 'icalendar/recurrence'

calendars = Icalendar.parse(File.read(path_to_ics)) # parse an ICS file
event = Array(calendars).first.events.first # retrieve the first event
event.occurrences_between(Date.parse("2014-01-01"), Date.parse("2014-02-01")) # get all occurrence for one month
```

### Working with occurrences

An event occurrence is a simple struct object with `start_time` and `end_time` methods.

```ruby
occurrence.start_time # => 2014-02-01 00:00:00 -0800
occurrence.end_time   # => 2014-02-02 00:00:00 -0800
```

### Daily event with excluded date (inline ICS example)

```ruby
require 'date' # for parse method
require 'icalendar/recurrence'

ics_string = <<-EOF
BEGIN:VCALENDAR
X-WR-CALNAME:Test Public
X-WR-CALID:f512e378-050c-4366-809a-ef471ce45b09:101165
PRODID:Zimbra-Calendar-Provider
VERSION:2.0
METHOD:PUBLISH
BEGIN:VEVENT
UID:efcb99ae-d540-419c-91fa-42cc2bd9d302
RRULE:FREQ=DAILY;INTERVAL=1
SUMMARY:Every day, except the 28th
DTSTART;VALUE=DATE:20140101
DTEND;VALUE=DATE:20140102
STATUS:CONFIRMED
CLASS:PUBLIC
X-MICROSOFT-CDO-ALLDAYEVENT:TRUE
TRANSP:TRANSPARENT
LAST-MODIFIED:20140113T200625Z
DTSTAMP:20140113T200625Z
SEQUENCE:0
EXDATE;VALUE=DATE:20140128
END:VEVENT
END:VCALENDAR
EOF

# An event that occurs every day, starting January 1, 2014 with one excluded 
# date. January 28, 2014 will not appear in the occurrences.
calendars = Icalendar.parse(ics_string)
every_day_except_jan_28 = Array(calendars).first.events.first
puts "Every day except January 28, 2014, occurrences from 2014-01-01 to 2014-02-01:"
puts every_day_except_jan_28.occurrences_between(Date.parse("2014-01-01"), Date.parse("2014-02-01"))
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/icalendar-recurrence/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
