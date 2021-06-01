# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Ticket::Number::Base
  extend self

  private

  # The algorithm to calculate the checksum is derived from the one
  # Deutsche Bundesbahn (german railway company) uses for calculation
  # of the check digit of their vehikel numbering.
  # The checksum is calculated by alternately multiplying the digits
  # with 1 and 2 and adding the resulsts from left to right of the
  # vehikel number. The modulus to 10 of this sum is substracted from
  # 10. See: http://www.pruefziffernberechnung.de/F/Fahrzeugnummer.shtml
  # (german)
  def checksum(number)
    chksum = 0
    mult   = 1

    number.to_s.chars.map(&:to_i).each do |digit|
      chksum += digit * mult
      mult    = (mult % 3) + 1
    end

    chksum = 10 - (chksum % 10)
    chksum.to_s[0]
  end
end
