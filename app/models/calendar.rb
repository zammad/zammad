# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Calendar < ApplicationModel
  include ChecksClientNotification
  include CanUniqName
  include HasEscalationCalculationImpact

  store :business_hours
  store :public_holidays

  before_create  :validate_public_holidays, :validate_hours, :fetch_ical
  after_create   :sync_default, :min_one_check
  before_update  :validate_public_holidays, :validate_hours, :fetch_ical
  after_update   :sync_default, :min_one_check
  after_destroy  :min_one_check

=begin

set initial default calendar

  calendar = Calendar.init_setup

returns calendar object

=end

  def self.init_setup(ip = nil)

    # ignore client ip if not public ip
    if ip && ip =~ %r{^(::1|127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.)}
      ip = nil
    end

    # prevent multiple setups for same ip
    cache = Cache.read('Calendar.init_setup.done')
    return if cache && cache[:ip] == ip

    Cache.write('Calendar.init_setup.done', { ip: ip }, { expires_in: 1.hour })

    # call for calendar suggestion
    calendar_details = Service::GeoCalendar.location(ip)
    return if calendar_details.blank?
    return if calendar_details['name'].blank?
    return if calendar_details['business_hours'].blank?

    calendar_details['name'] = Calendar.generate_uniq_name(calendar_details['name'])
    calendar_details['default'] = true
    calendar_details['created_by_id'] = 1
    calendar_details['updated_by_id'] = 1

    # find if auto generated calendar exists
    calendar = Calendar.find_by(default: true, updated_by_id: 1, created_by_id: 1)
    if calendar
      calendar.update!(calendar_details)
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

returns preset of ical feeds

  feeds = Calendar.ical_feeds

returns

  {
    'http://www.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics' => 'US',
    ...
  }

=end

  def self.ical_feeds
    data = YAML.load_file(Rails.root.join('config/holiday_calendars.yml'))
    url  = data['url']

    data['countries'].map do |country, domain|
      [format(url, domain: domain), country]
    end.to_h
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
    TZInfo::Timezone.all_country_zone_identifiers.each do |timezone|
      t = TZInfo::Timezone.get(timezone)
      diff = t.current_period.utc_total_offset / 60 / 60
      list[ timezone ] = diff
    end
    list
  end

=begin

syn all calendars with ical feeds

  success = Calendar.sync

returns

  true # or false

=end

  def self.sync
    Calendar.find_each(&:sync)
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

    # only sync every 5 days
    if id
      cache_key = "CalendarIcal::#{id}"
      cache = Cache.read(cache_key)
      return if !last_log && cache && cache[:ical_url] == ical_url
    end

    begin
      events = {}
      if ical_url.present?
        events = Calendar.fetch_parse(ical_url)
      end

      # sync with public_holidays
      self.public_holidays ||= {}

      # remove old ical entries if feed has changed
      public_holidays.each do |day, meta|
        next if !public_holidays[day]['feed']
        next if meta['feed'] == Digest::MD5.hexdigest(ical_url)

        public_holidays.delete(day)
      end

      # sync new ical feed dates
      events.each do |day, summary|
        public_holidays[day] ||= {}

        # ignore if already added or changed
        next if public_holidays[day].key?('active')

        # entry already exists
        next if summary == public_holidays[day][:summary]

        # create new entry
        public_holidays[day] = {
          active:  true,
          summary: summary,
          feed:    Digest::MD5.hexdigest(ical_url)
        }
      end
      self.last_log = nil
      if id
        Cache.write(
          cache_key,
          { public_holidays: public_holidays, ical_url: ical_url },
          { expires_in: 1.day },
        )
      end
    rescue => e
      self.last_log = e.inspect
    end

    self.last_sync = Time.zone.now
    if !without_save
      save
    end
    true
  end

  def self.fetch_parse(location)
    if location.match?(%r{^http}i)
      result = UserAgent.get(location)
      if !result.success?
        raise result.error
      end

      cal_file = result.body
    else
      cal_file = File.open(location)
    end

    cals = Icalendar::Calendar.parse(cal_file)
    cal = cals.first
    events = {}
    cal.events.each do |event|
      if event.rrule

        # loop till days
        interval_frame_start = Date.parse("#{Time.zone.now - 1.year}-01-01")
        interval_frame_end   = Date.parse("#{Time.zone.now + 3.years}-12-31")
        occurrences          = event.occurrences_between(interval_frame_start, interval_frame_end)
        if occurrences.present?
          occurrences.each do |occurrence|
            result = Calendar.day_and_comment_by_event(event, occurrence.start_time)
            next if !result

            events[result[0]] = result[1]
          end
        end
      end
      next if event.dtstart < Time.zone.now - 1.year
      next if event.dtstart > Time.zone.now + 3.years

      result = Calendar.day_and_comment_by_event(event, event.dtstart)
      next if !result

      events[result[0]] = result[1]
    end
    events.sort.to_h
  end

  # get day and comment by event
  def self.day_and_comment_by_event(event, start_time)
    day = "#{start_time.year}-#{format('%<month>02d', month: start_time.month)}-#{format('%<day>02d', day: start_time.day)}"
    comment = event.summary || event.description
    comment = comment.to_utf8(fallback: :read_as_sanitized_binary)

    # ignore daylight saving time entries
    return if comment.match?(%r{(daylight saving|sommerzeit|summertime)}i)

    [day, comment]
  end

=begin

  calendar = Calendar.find(123)
  calendar.business_hours_to_hash

returns

  {
    mon: {'09:00' => '18:00'},
    tue: {'09:00' => '18:00'},
    wed: {'09:00' => '18:00'},
    thu: {'09:00' => '18:00'},
    sat: {'09:00' => '18:00'}
  }

=end

  def business_hours_to_hash
    business_hours
      .filter { |_, value| value[:active] && value[:timeframes] }
      .each_with_object({}) do |(day, meta), days_memo|
        days_memo[day.to_sym] = meta[:timeframes]
          .each_with_object({}) do |(from, to), hours_memo|
            next if !from || !to

            # convert "last minute of the day" format from Zammad/UI to biz-gem
            hours_memo[from] = to == '23:59' ? '24:00' : to
          end
      end
  end

=begin

  calendar = Calendar.find(123)
  calendar.public_holidays_to_array

returns

  [
    Thu, 08 Mar 2020,
    Sun, 25 Mar 2020,
    Thu, 29 Mar 2020,
  ]

=end

  def public_holidays_to_array
    holidays = []
    public_holidays&.each do |day, meta|
      next if !meta
      next if !meta['active']
      next if meta['removed']

      holidays.push Date.parse(day)
    end
    holidays
  end

  def biz(breaks: {})
    Biz::Schedule.new do |config|

      # get business hours
      hours = business_hours_to_hash
      raise "No configured hours found in calendar #{inspect}" if hours.blank?

      config.hours = hours

      # get holidays
      config.holidays = public_holidays_to_array

      config.time_zone = timezone

      config.breaks = breaks
    end
  end

  private

  # if changed calendar is default, set all others default to false
  def sync_default
    return true if !default

    Calendar.find_each do |calendar|
      next if calendar.id == id
      next if !calendar.default

      calendar.default = false
      calendar.save
    end
    true
  end

  # check if min one is set to default true
  def min_one_check
    if !Calendar.exists?(default: true)
      first = Calendar.order(:created_at, :id).limit(1).first
      return true if !first

      first.default = true
      first.save
    end

    # check if sla's are refer to an existing calendar
    default_calendar = Calendar.find_by(default: true)
    Sla.find_each do |sla|
      if !sla.calendar_id
        sla.calendar_id = default_calendar.id
        sla.save!
        next
      end
      if !Calendar.exists?(id: sla.calendar_id)
        sla.calendar_id = default_calendar.id
        sla.save!
      end
    end
    true
  end

  # fetch ical feed
  def fetch_ical
    sync(true)
    true
  end

  # validate format of public holidays
  def validate_public_holidays

    # fillup feed info
    before = public_holidays_was
    public_holidays.each do |day, meta|
      if before && before[day] && before[day]['feed']
        meta['feed'] = before[day]['feed']
      end
      meta['active'] = if meta['active']
                         true
                       else
                         false
                       end
    end
    true
  end

  # validate business hours
  def validate_hours

    # get business hours
    hours = business_hours_to_hash
    raise Exceptions::UnprocessableEntity, 'No configured business hours found!' if hours.blank?

    # validate if business hours are usable by execute a try calculation
    begin
      Biz.configure do |config|
        config.hours = hours
      end
      Biz.time(10, :minutes).after(Time.zone.parse('Tue, 05 Feb 2019 21:40:28 UTC +00:00'))
    rescue => e
      raise Exceptions::UnprocessableEntity, e.message
    end

    true
  end

end
