# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Calendar < ApplicationModel
  store :business_hours
  store :public_holidays

  after_create   :sync_default, :min_one_check
  after_update   :sync_default, :min_one_check
  after_destroy  :min_one_check

=begin

set inital default calendar

  calendar = Calendar.init_setup

returns calendar object

=end

  def self.init_setup(ip = nil)

    # call for calendar suggestion
    calendar_details = Service::GeoCalendar.location(ip)
    return if !calendar_details

    calendar_details['name'] = Calendar.genrate_uniq_name(calendar_details['name'])
    calendar_details['default'] = true
    calendar_details['created_by_id'] = 1
    calendar_details['updated_by_id'] = 1

    # find if auto generated calendar exists
    calendar = Calendar.find_by(default: true, updated_by_id: 1, created_by_id: 1)
    if calendar
      calendar.update_attributes(calendar_details)
      return calendar
    end
    create(calendar_details)
  end

=begin

get default calendar

  calendar = Calendar.default

returns calendar object

=end

  def self.default
    find_by(default: true)
  end

=begin

returnes preset of ical feeds

  feeds = Calendar.ical_feeds

returns

  {
    'US' => 'http://www.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics',
    ...
  }

=end

  def self.ical_feeds
    gfeeds = {
      'Australian' => 'en.australian',
      'Austrian' => 'de.austrian',
      'Argentina' => 'en.ar',
      'Bahamas' => 'en.bs',
      'Belarus' => 'en.by',
      'Brazilian' => 'en.brazilian',
      'Bulgaria' => 'en.bulgarian',
      'Canadian' => 'en.canadian',
      'China' => 'en.china',
      'Chile' => 'en.cl',
      'Costa Rica' => 'en.cr',
      'Colombia' => 'en.co',
      'Croatia' => 'en.croatian',
      'Cuba' => 'en.cu',
      'Cyprus' => 'de.cy',
      'Switzerland' => 'de.ch',
      'Christian' => 'en.christian',
      'Danish' => 'da.danish',
      'Dutch' => 'nl.dutch',
      'Egypt' => 'en.eg',
      'Ethiopia' => 'en.et',
      'Ecuador' => 'en.ec',
      'Estonia' => 'en.ee',
      'Finnish' => 'en.finnish',
      'French' => 'en.french',
      'German' => 'de.german',
      'Greek' => 'en.greek',
      'Ghana' => 'en.gh',
      'Hong Kong' => 'en.hong_kong',
      'Haiti' => 'en.ht',
      'Hungary' => 'en.hungarian',
      'Indian' => 'en.indian',
      'Indonesian' => 'en.indonesian',
      'Iranian' => 'en.ir',
      'Irish' => 'en.irish',
      'Islamic' => 'en.islamic',
      'Italian' => 'it.italian',
      'Israel' => 'en.jewish',
      'Japanese' => 'en.japanese',
      'Jewish' => 'en.jewish',
      'Kuwait' => 'en.kw',
      'Latvia' => 'en.latvian',
      'Liechtenstein' => 'en.li',
      'Lithuania' => 'en.lithuanian',
      'Luxembourg' => 'en.lu',
      'Malaysian' => 'en.malaysia',
      'Mexican' => 'en.mexican',
      'Morocco' => 'en.ma',
      'Mauritius' => 'en.mu',
      'Moldova' => 'en.md',
      'New Zealand' => 'en.new_zealand',
      'Norwegian' => 'en.norwegian',
      'Philippines' => 'en.philippines',
      'Polish' => 'en.polish',
      'Portuguese' => 'en.portuguese',
      'Pakistan' => 'en.pk',
      'Russian' => 'en.russian',
      'Senegal' => 'en.sn',
      'Singapore' => 'en.singapore',
      'South Africa' => 'en.sa',
      'South Korean' => 'en.south_korea',
      'Spain' => 'en.spain',
      'Slovakia' => 'en.slovak',
      'Serbia' => 'en.rs',
      'Slovenia' => 'en.slovenian',
      'Swedish' => 'en.swedish',
      'Taiwan' => 'en.taiwan',
      'Thai' => 'en.th',
      'Turkey' => 'en.turkish',
      'UK' => 'en.uk',
      'US' => 'en.usa',
      'Ukraine' => 'en.ukrainian',
      'Uruguay' => 'en.uy',
      'Vietnamese' => 'en.vietnamese',
      'Venezuela' => 'en.ve',
    }
    all_feeds = {}
    gfeeds.each {|key, name|
      all_feeds["http://www.google.com/calendar/ical/#{name}%23holiday%40group.v.calendar.google.com/public/basic.ics"] = "#{key} - Holidays"
    }
    all_feeds
  end

=begin

get list of available timezones and UTC offsets

  list = Calendar.timezones

returns

  {
    'America/Los_Angeles' => -7
    ...
  }

=end

  def self.timezones
    list = {}
    TZInfo::Timezone.all_country_zone_identifiers.each { |timezone|
      t = TZInfo::Timezone.get(timezone)
      diff = t.current_period.utc_total_offset / 60 / 60
      list[ timezone ] = diff
    }
    list
  end

=begin

syn all calendars with ical feeds

  success = Calendar.sync

returns

  true # or false

=end

  def self.sync
    Calendar.all.each(&:sync)
    true
  end

=begin

syn one calendars with ical feed

  calendar = Calendar.find(4711)
  success = calendar.sync

returns

  true # or false

=end

  def sync
    return if !ical_url
    events = Calendar.parse(ical_url)

    # sync with public_holidays
    if !public_holidays
      self.public_holidays = {}
    end
    events.each {|day, summary|
      if !public_holidays[day]
        public_holidays[day] = {}
      end

      # ignore if already added or changed
      next if public_holidays[day].key?('active')

      # create new entry
      public_holidays[day] = {
        active: true,
        summary: summary,
      }
    }
    self.last_log = ''
    self.last_sync = Time.zone.now
    save
    true
  end

  def self.parse(location)
    if location =~ /^http/i
      result = UserAgent.get(location)
      cal_file = result.body
    else
      cal_file = File.open(location)
    end

    cals = Icalendar.parse(cal_file)
    cal = cals.first
    events = {}
    cal.events.each {|event|
      next if event.dtstart < Time.zone.now - 1.year
      next if event.dtstart > Time.zone.now + 3.year
      day = "#{event.dtstart.year}-#{format('%02d', event.dtstart.month)}-#{format('%02d', event.dtstart.day)}"
      comment = event.summary || event.description
      comment = Encode.conv( 'utf8', comment.to_s.force_encoding('utf-8') )
      if !comment.valid_encoding?
        comment = comment.encode('utf-8', 'binary', invalid: :replace, undef: :replace, replace: '?')
      end

      # ignore daylight saving time entries
      next if comment =~ /(daylight saving|sommerzeit|summertime)/i
      events[day] = comment
    }
    events.sort.to_h
  end

  private

  # if changed calendar is default, set all others default to false
  def sync_default
    return if !default
    Calendar.all.each {|calendar|
      next if calendar.id == id
      next if !calendar.default
      calendar.default = false
      calendar.save
    }
  end

  # check if min one is set to default true
  def min_one_check
    Calendar.all.each {|calendar|
      return true if calendar.default
    }
    first = Calendar.order(:created_at, :id).limit(1).first
    first.default = true
    first.save

    # check if sla's are refer to an existing calendar
    Sla.all.each {|sla|
      if !sla.calendar_id
        sla.calendar_id = first.id
        sla.save
        next
      end
      if !Calendar.find_by(id: sla.calendar_id)
        sla.calendar_id = first.id
        sla.save
      end
    }
  end
end
