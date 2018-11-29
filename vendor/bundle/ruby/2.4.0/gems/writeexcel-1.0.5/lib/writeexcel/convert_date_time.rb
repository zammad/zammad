# -*- encoding: utf-8 -*-
module ConvertDateTime
  #
  # The function takes a date and time in ISO8601 "yyyy-mm-ddThh:mm:ss.ss" format
  # and converts it to a decimal number representing a valid Excel date.
  #
  # Dates and times in Excel are represented by real numbers. The integer part of
  # the number stores the number of days since the epoch and the fractional part
  # stores the percentage of the day in seconds. The epoch can be either 1900 or
  # 1904.
  #
  # Parameter: Date and time string in one of the following formats:
  #               yyyy-mm-ddThh:mm:ss.ss  # Standard
  #               yyyy-mm-ddT             # Date only
  #                         Thh:mm:ss.ss  # Time only
  #
  # Returns:
  #            A decimal number representing a valid Excel date, or
  #            undef if the date is invalid.
  #
  def convert_date_time(date_time_string, date_1904 = false)       #:nodoc:
    date_time = date_time_string.sub(/^\s+/, '').sub(/\s+$/, '').sub(/Z$/, '')

    # Check for invalid date char.
    return nil if date_time =~ /[^0-9T:\-\.Z]/

    # Check for "T" after date or before time.
    return nil unless date_time =~ /\dT|T\d/

    seconds   = 0 # Time expressed as fraction of 24h hours in seconds

    # Split into date and time.
    date, time = date_time.split(/T/)

    # We allow the time portion of the input DateTime to be optional.
    if time
      # Match hh:mm:ss.sss+ where the seconds are optional
      if time =~ /^(\d\d):(\d\d)(:(\d\d(\.\d+)?))?/
        hour   = $1.to_i
        min    = $2.to_i
        sec    = $4.to_f || 0
      else
        return nil # Not a valid time format.
      end

      # Some boundary checks
      return nil if hour >= 24
      return nil if min  >= 60
      return nil if sec  >= 60

      # Excel expresses seconds as a fraction of the number in 24 hours.
      seconds = (hour * 60* 60 + min * 60 + sec) / (24.0 * 60 * 60)
    end

    # We allow the date portion of the input DateTime to be optional.
    return seconds if date == ''

    # Match date as yyyy-mm-dd.
    if date =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/
      year   = $1.to_i
      month  = $2.to_i
      day    = $3.to_i
    else
      return nil  # Not a valid date format.
    end

    # Set the epoch as 1900 or 1904. Defaults to 1900.
    # Special cases for Excel.
    unless date_1904
      return      seconds if date == '1899-12-31' # Excel 1900 epoch
      return      seconds if date == '1900-01-00' # Excel 1900 epoch
      return 60 + seconds if date == '1900-02-29' # Excel false leapday
    end


    # We calculate the date by calculating the number of days since the epoch
    # and adjust for the number of leap days. We calculate the number of leap
    # days by normalising the year in relation to the epoch. Thus the year 2000
    # becomes 100 for 4 and 100 year leapdays and 400 for 400 year leapdays.
    #
    epoch   = date_1904 ? 1904 : 1900
    offset  = date_1904 ?    4 :    0
    norm    = 300
    range   = year -epoch

    # Set month days and check for leap year.
    mdays   = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    leap    = 0
    leap    = 1  if year % 4 == 0 && year % 100 != 0 || year % 400 == 0
    mdays[1]   = 29 if leap != 0

    # Some boundary checks
    return nil if year  < epoch or year  > 9999
    return nil if month < 1     or month > 12
    return nil if day   < 1     or day   > mdays[month -1]

    # Accumulate the number of days since the epoch.
    days = mdays[0, month - 1].inject(day) {|result, mday| result + mday} # days from 1, Jan
    days += range *365                       # Add days for past years
    days += ((range)                /  4)    # Add leapdays
    days -= ((range + offset)       /100)    # Subtract 100 year leapdays
    days += ((range + offset + norm)/400)    # Add 400 year leapdays
    days -= leap                             # Already counted above

    # Adjust for Excel erroneously treating 1900 as a leap year.
    days += 1 if !date_1904 and days > 59

    days + seconds
  end
end
