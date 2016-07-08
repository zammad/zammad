# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Calendar < ApplicationModel
  store :business_hours
  store :public_holidays

  before_create  :validate_public_holidays, :fetch_ical
  before_update  :validate_public_holidays, :fetch_ical
  after_create   :sync_default, :min_one_check
  after_update   :sync_default, :min_one_check
  after_destroy  :min_one_check

  notify_clients_support

=begin

set inital default calendar

  calendar = Calendar.init_setup

returns calendar object

=end

  def self.init_setup(ip = nil)

    # ignore client ip if not public ip
    if ip && ip =~ /^(::1|127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.)/
      ip = nil
    end

    # prevent multible setups for same ip
    cache = Cache.get('Calendar.init_setup.done')
    return if cache && cache[:ip] == ip
    Cache.write('Calendar.init_setup.done', { ip: ip }, { expires_in: 1.hour })

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
      'Australia' => 'en.australian',
      'Austria' => 'de.austrian',
      'Argentina' => 'en.ar',
      'Bahamas' => 'en.bs',
      'Belarus' => 'en.by',
      'Brazil' => 'en.brazilian',
      'Bulgaria' => 'en.bulgarian',
      'Canada' => 'en.canadian',
      'China' => 'en.china',
      'Chile' => 'en.cl',
      'Costa Rica' => 'en.cr',
      'Colombia' => 'en.co',
      'Croatia' => 'en.croatian',
      'Cuba' => 'en.cu',
      'Cyprus' => 'de.cy',
      'Switzerland' => 'de.ch',
      'Denmark' => 'da.danish',
      'Netherlands' => 'nl.dutch',
      'Egypt' => 'en.eg',
      'Ethiopia' => 'en.et',
      'Ecuador' => 'en.ec',
      'Estonia' => 'en.ee',
      'Finland' => 'en.finnish',
      'France' => 'en.french',
      'Germany' => 'de.german',
      'Greece' => 'en.greek',
      'Ghana' => 'en.gh',
      'Hong Kong' => 'en.hong_kong',
      'Haiti' => 'en.ht',
      'Hungary' => 'en.hungarian',
      'India' => 'en.indian',
      'Indonesia' => 'en.indonesian',
      'Iran' => 'en.ir',
      'Ireland' => 'en.irish',
      'Italy' => 'it.italian',
      'Israel' => 'en.jewish',
      'Japan' => 'en.japanese',
      'Kuwait' => 'en.kw',
      'Latvia' => 'en.latvian',
      'Liechtenstein' => 'en.li',
      'Lithuania' => 'en.lithuanian',
      'Luxembourg' => 'en.lu',
      'Malaysia' => 'en.malaysia',
      'Mexico' => 'en.mexican',
      'Morocco' => 'en.ma',
      'Mauritius' => 'en.mu',
      'Moldova' => 'en.md',
      'New Zealand' => 'en.new_zealand',
      'Norway' => 'en.norwegian',
      'Philippines' => 'en.philippines',
      'Poland' => 'en.polish',
      'Portugal' => 'en.portuguese',
      'Pakistan' => 'en.pk',
      'Russia' => 'en.russian',
      'Senegal' => 'en.sn',
      'Singapore' => 'en.singapore',
      'South Africa' => 'en.sa',
      'South Korean' => 'en.south_korea',
      'Spain' => 'en.spain',
      'Slovakia' => 'en.slovak',
      'Serbia' => 'en.rs',
      'Slovenia' => 'en.slovenian',
      'Sweden' => 'en.swedish',
      'Taiwan' => 'en.taiwan',
      'Thai' => 'en.th',
      'Turkey' => 'en.turkish',
      'UK' => 'en.uk',
      'US' => 'en.usa',
      'Ukraine' => 'en.ukrainian',
      'Uruguay' => 'en.uy',
      'Vietnam' => 'en.vietnamese',
      'Venezuela' => 'en.ve',
    }
    all_feeds = {}
    gfeeds.each { |key, name|
      all_feeds["http://www.google.com/calendar/ical/#{name}%23holiday%40group.v.calendar.google.com/public/basic.ics"] = key
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

  def sync(without_save = nil)
    return if !ical_url
    begin
      events = {}
      if ical_url && !ical_url.empty?
        events = Calendar.parse(ical_url)
      end

      # sync with public_holidays
      if !public_holidays
        self.public_holidays = {}
      end

      # remove old ical entries if feed has changed
      public_holidays.each { |day, meta|
        next if !public_holidays[day]['feed']
        next if meta['feed'] == Digest::MD5.hexdigest(ical_url)
        public_holidays.delete(day)
      }

      # sync new ical feed dates
      events.each { |day, summary|
        if !public_holidays[day]
          public_holidays[day] = {}
        end

        # ignore if already added or changed
        next if public_holidays[day].key?('active')

        # create new entry
        public_holidays[day] = {
          active: true,
          summary: summary,
          feed: Digest::MD5.hexdigest(ical_url)
        }
      }
      self.last_log = nil
    rescue => e
      self.last_log = e.inspect
    end

    self.last_sync = Time.zone.now
    if !without_save
      save
    end
    true
  end

  def self.parse(location)
    if location =~ /^http/i
      result = UserAgent.get(location)
      if !result.success?
        raise result.error
      end
      cal_file = result.body
    else
      cal_file = File.open(location)
    end

    cals = Icalendar.parse(cal_file)
    cal = cals.first
    events = {}
    cal.events.each { |event|
      next if event.dtstart < Time.zone.now - 1.year
      next if event.dtstart > Time.zone.now + 3.years
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
    Calendar.all.each { |calendar|
      next if calendar.id == id
      next if !calendar.default
      calendar.default = false
      calendar.save
    }
  end

  # check if min one is set to default true
  def min_one_check
    Calendar.all.each { |calendar|
      return true if calendar.default
    }
    first = Calendar.order(:created_at, :id).limit(1).first
    first.default = true
    first.save

    # check if sla's are refer to an existing calendar
    Sla.all.each { |sla|
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

  # fetch ical feed
  def fetch_ical
    sync(true)
  end

  # validate format of public holidays
  def validate_public_holidays

    # fillup feed info
    public_holidays.each { |day, meta|
      if public_holidays_was && public_holidays_was[day] && public_holidays_was[day]['feed']
        meta['feed'] = public_holidays_was[day]['feed']
      end
      meta['active'] = if meta['active']
                         true
                       else
                         false
                       end
    }

  end
end
