#require 'iconv'
module Encode
  def self.conv (charset, string)

    # return if string is false
    return string if !string

    # if no charset is given, use LATIN1 as default
    if !charset || charset == 'US-ASCII' || charset == 'ASCII-8BIT'
      charset = 'LATIN1'
    end

    # validate already existing utf8 strings
    if charset.downcase == 'utf8' || charset.downcase == 'utf-8'
      begin

        # return if encoding is valid
        utf8 = string.force_encoding('UTF-8')
        return utf8 if utf8.valid_encoding?

        # try to encode from Windows-1252 to utf8
        string.encode!( 'UTF-8', 'Windows-1252' )

      rescue EncodingError => e
        puts "Bad encoding: #{string.inspect}"
        string.encode!( 'UTF-8', invalid: :replace, undef: :replace, replace: '?' )
      end
      return string
    end

#    puts '-------' + charset
#    puts string
    # convert string
    string.encode!( 'UTF-8', charset.upcase )
#    Iconv.conv( 'UTF8', charset, string )
  end
end