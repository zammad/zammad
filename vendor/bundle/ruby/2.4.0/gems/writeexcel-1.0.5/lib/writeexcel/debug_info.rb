# -*- coding: utf-8 -*-

require 'writeexcel/caller_info'

if defined?($writeexcel_debug)
  class BIFFWriter
    include CallerInfo

    def append(*args)
      data =
        ruby_18 { args.join } ||
        ruby_19 { args.collect{ |arg| arg.dup.force_encoding('ASCII-8BIT') }.join }
      print_caller_info(data, :method => 'append')
      super
    end

    def prepend(*args)
      data =
        ruby_18 { args.join } ||
        ruby_19 { args.collect{ |arg| arg.dup.force_encoding('ASCII-8BIT') }.join }
      print_caller_info(data, :method => 'prepend')
      super
    end

    def print_caller_info(data, param = {})
      infos = caller_info

      print "#{param[:method]}\n" if param[:method]
      infos.each do |info|
        print "#{info[:file]}:#{info[:line]}"
        print " in #{info[:method]}" if info[:method]
        print "\n"
      end
      print unpack_record(data) + "\n\n"
    end

    def unpack_record(data)  # :nodoc:
      data.unpack('C*').map! {|c| sprintf("%02X", c) }.join(' ')
    end
  end
end
