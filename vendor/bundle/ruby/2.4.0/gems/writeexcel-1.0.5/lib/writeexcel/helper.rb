# -*- coding: utf-8 -*-
#
# helper.rb
#
  # Convert to US_ASCII encoding if ascii characters only.
  def convert_to_ascii_if_ascii(str)
    return nil if str.nil?
    ruby_18 do
      unless str =~ /[^!"#\$%&'\(\)\*\+,\-\.\/\:\;<=>\?@0-9A-Za-z_\[\\\]\{\}^` ~\0\n]/
        str = String.new(str)
      end
    end ||
    ruby_19 do
      if str.ascii_only?
        str = [str].pack('a*')
      end
    end
    str
  end
  private :convert_to_ascii_if_ascii

  def utf16be_to_16le(utf16be)
    utf16be.unpack('n*').pack('v*')
  end

  def utf8_to_16be(utf8)
    ruby_18 { NKF.nkf('-w16B0 -m0 -W', utf8) } ||
    ruby_19 do
      utf16be = utf8.encode('UTF-16BE')
      utf16be.force_encoding('UTF-16BE')
    end
  end
  private :utf8_to_16be

  def utf8_to_16le(utf8)
    ruby_18 { NKF.nkf('-w16L0 -m0 -W', utf8) } ||
    ruby_19 do
      utf16le = utf8.encode('UTF-16LE')
      utf16le.force_encoding('UTF-16LE')
    end
  end
  private :utf8_to_16le

  def ascii_to_16be(ascii)
    ascii.unpack("C*").pack("n*")
    ruby_19 { ascii.force_encoding('UTF-16BE') }
    ascii
  end
  private :ascii_to_16be

  def store_simple(record, length, *args)
    header = [record, length].pack('vv')
    data = args.collect { |arg| [arg].pack('v') }.join('')

    append(header, data)
  end
  private :store_simple

  # Convert base26 column string to a number.
  # All your Base are belong to us.
  def chars_to_col(chars)
    expn = 0
    col  = 0
    while (!chars.empty?)
      char = chars.pop   # LS char first
      col  += (char.ord - "A".ord + 1) * (26 ** expn)
      expn += 1
    end
    col
  end
  private :chars_to_col

  NonAscii = /[^!"#\$%&'\(\)\*\+,\-\.\/\:\;<=>\?@0-9A-Za-z_\[\\\]\{\}^` ~\0\n]/

  def is_utf8?(str)
    ruby_18 { str =~ NonAscii } ||
    ruby_19 { str.encoding == Encoding::UTF_8 }
  end
