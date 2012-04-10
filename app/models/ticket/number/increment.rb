module Ticket::Number::Increment
  extend self  

  def number_generate_item

    # get config
    config = Setting.get('ticket_number_increment')

    # read counter
    min_digs  = config[:min_size] || 4;
    file_name = config[:file] || '/tmp/counter.log'
    contents = ""
    begin
      file = File.open( file_name )
      file.each {|line|
        contents << line
      }
      file.close
    rescue
      contents = '0'
    end

    # increase counter
    counter, date_file = contents.to_s.split(';')
    counter = counter.to_i + 1
    contents = counter.to_s + ';'

    # write counter
    file = File.open( file_name, 'w' )
    file.write(contents)
    file.close

    # fill up number counter
    if config[:checksum]
      min_digs = min_digs.to_i - 1
    end
    fillup = Setting.get('system_id') || '1'
    ( 1..100 ).each do |i|
      if ( fillup.length.to_i + counter.to_s.length.to_i ) < min_digs.to_i
        fillup = fillup + '0'
      end
    end
    number = fillup.to_s + counter.to_s
    
    # calculate a checksum
    # The algorithm to calculate the checksum is derived from the one
    # Deutsche Bundesbahn (german railway company) uses for calculation
    # of the check digit of their vehikel numbering.
    # The checksum is calculated by alternately multiplying the digits
    # with 1 and 2 and adding the resulsts from left to right of the
    # vehikel number. The modulus to 10 of this sum is substracted from
    # 10. See: http://www.pruefziffernberechnung.de/F/Fahrzeugnummer.shtml
    # (german)
    if config[:checksum]
      chksum = 0
      mult   = 1
      (1..number.length).each do |i|
        digit = number.to_s[i, 1]
        chksum = chksum + ( mult * digit.to_i )
        mult += 1;
        if mult == 3
          mult = 1;
        end
      end
      chksum %= 10
      chksum = 10 - chksum
      if chksum == 10
        chksum = 1
      end
      number += chksum.to_s
    end
    return number
  end

  def number_check_item (string)

    # get config
    system_id           = Setting.get('system_id') || ''
    ticket_hook         = Setting.get('ticket_hook')
    ticket_hook_divider = Setting.get('ticket_hook_divider') || ''
    ticket              = nil
    
    # probe format
    if string =~ /#{ticket_hook}#{ticket_hook_divider}(#{system_id}\d{2,50})/i then
      ticket = Ticket.where( :number => $1 ).first
    elsif string =~ /#{ticket_hook}\s{0,2}(#{system_id}\d{2,50})/i then
      ticket = Ticket.where( :number => $1 ).first
    end
    return ticket
  end
end