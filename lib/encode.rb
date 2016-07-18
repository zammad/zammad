#require 'iconv'
module Encode
  def self.conv (charset, string)

    # return if string is false
    return string if !string

    # if no charset is given, use LATIN1 as default
    if !charset || charset == 'US-ASCII' || charset == 'ASCII-8BIT'
      charset = 'ISO-8859-15'
    end

    # validate already existing utf8 strings
    if charset.casecmp('utf8').zero? || charset.casecmp('utf-8').zero?
      begin

        # return if encoding is valid
        utf8 = string.dup.force_encoding('UTF-8')
        return utf8 if utf8.valid_encoding?

        # try to encode from Windows-1252 to utf8
        string.encode!('UTF-8', 'Windows-1252')

      rescue EncodingError => e
        Rails.logger.error "Bad encoding: #{string.inspect}"
        string = string.encode!('UTF-8', invalid: :replace, undef: :replace, replace: '?')
      end
      return string
    end

    # convert string
    begin
      string.encode!('UTF-8', charset)
    rescue => e
      Rails.logger.error 'ERROR: ' + e.inspect
      string
    end
    #Iconv.conv( 'UTF8', charset, string)
  end
end
