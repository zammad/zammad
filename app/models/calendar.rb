# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Calendar < ApplicationModel
  include ChecksClientNotification
  include HasAuditLogs
  include CanUniqName
  include HasEscalationCalculationImpact

  self.audit_log_attributes_ignored = %i[last_log last_sync public_holidays]

  store :business_hours
  store :public_holidays

  validates :name, uniqueness: { case_sensitive: false }
  validate :validate_hours
  validate :validate_ical_url_format

  before_save :ensure_public_holidays_details, :fetch_ical

  after_destroy :min_one_check
  after_save    :min_one_check

  after_save :sync_default

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
    cache = Rails.cache.read('Calendar.init_setup.done')
    return if cache && cache[:ip] == ip

    Rails.cache.write('Calendar.init_setup.done', { ip: ip }, { expires_in: 1.hour })

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

    data['countries'].to_h do |country, domain|
      [format(url, domain: domain), country]
    end
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
    TZInfo::Timezone.all_identifiers.each do |timezone|
      t = ActiveSupport::TimeZone.find_tzinfo(timezone)
      diff = t.current_period.utc_total_offset / 60 / 60
      list[ timezone ] = diff
    end
    list
  end

=begin

sync all calendars with ical feeds

  success = Calendar.sync

returns

  true

=end

  def self.sync
    Calendar.find_each do |calendar|
      calendar.sync_ical
    rescue ActiveRecord::AdapterError
      raise
    rescue => e
      Rails.logger.error "Calendar ##{calendar.id}: #{e.inspect}"
      Rails.logger.error e.backtrace.join("\n")
    end
    true
  end

=begin

sync one calendar with its ical feed

  calendar = Calendar.find(4711)
  synced = calendar.sync_ical

returns

  true  # the feed was synced, its outcome is in #last_log
  false # nothing was synced: no feed, a warm cache, or the calendar could not be saved

=end

  def sync_ical
    return false if ical_url.blank?

    Service::Calendar::Ical::Sync.execute(calendar: self)
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

  def validate_ical_url_format
    return if ical_url.blank?
    return if ical_url.to_s.match?(%r{\Ahttps?://}i)

    errors.add(:ical_url, __('must be a valid HTTP(S) URL'))
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
      first = Calendar.reorder(:created_at, :id).limit(1).first
      return true if !first

      first.default = true
      first.save
    end

    # check if sla's are refer to an existing calendar
    if destroyed?
      default_calendar = Calendar.find_by(default: true)
      Sla.where(calendar_id: id).find_each do |sla|
        sla.calendar_id = default_calendar.id
        sla.save!
      end
    end

    true
  end

  # fetch ical feed
  def fetch_ical
    return true if !ical_url_changed?

    Service::Calendar::Ical::Sync.execute(calendar: self, save: false)
    true
  end

  # ensure integrity of details of public holidays
  def ensure_public_holidays_details

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

    if hours.blank?
      errors.add :base, __('There are no business hours configured.')
      return
    end

    # raise Exceptions::UnprocessableContent, 'There are no business hours configured.' if hours.blank?

    # validate if business hours are usable by execute a try calculation
    begin
      Biz.configure do |config|
        config.hours = hours
      end
      Biz.time(10, :minutes).after(Time.zone.parse('Tue, 05 Feb 2019 21:40:28 UTC +00:00'))
    rescue => e
      errors.add :base, e.message
    end
  end

end
