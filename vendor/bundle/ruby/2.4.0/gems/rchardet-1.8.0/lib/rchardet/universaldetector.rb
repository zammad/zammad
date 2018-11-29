# encoding: US-ASCII
######################## BEGIN LICENSE BLOCK ########################
# The Original Code is Mozilla Universal charset detector code.
#
# The Initial Developer of the Original Code is
# Netscape Communications Corporation.
# Portions created by the Initial Developer are Copyright (C) 2001
# the Initial Developer. All Rights Reserved.
#
# Contributor(s):
#   Jeff Hodges - port to Ruby
#   Mark Pilgrim - port to Python
#   Shy Shalom - original C code
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301  USA
######################### END LICENSE BLOCK #########################

module CharDet
  MINIMUM_DATA_THRESHOLD = 4
  MINIMUM_THRESHOLD = 0.20
  EPureAscii = 0
  EEscAscii = 1
  EHighbyte = 2

  class UniversalDetector
    attr_reader :done, :result

    def initialize
      @highBitDetector = /[\x80-\xFF]/n
      @escDetector = /(\033|\~\{)/n
      @escCharSetProber = nil
      @charSetProbers = []
      reset()
    end

    def reset
      @result = {'encoding' => nil, 'confidence' => 0.0}
      @done = false
      @start = true
      @gotData = false
      @inputState = EPureAscii
      @lastChar = ''
      if @escCharSetProber
        @escCharSetProber.reset()
      end
      for prober in @charSetProbers
        prober.reset()
      end
    end

    def feed(aBuf)
      return if @done

      aLen = aBuf.length
      return if aLen == 0

      if !@gotData
        # If the data starts with BOM, we know it is UTF
        if aBuf[0, 3] == "\xEF\xBB\xBF"
          # EF BB BF  UTF-8 with BOM
          @result = {'encoding' => "UTF-8", 'confidence' => 1.0}
        elsif aBuf[0, 4] == "\xFF\xFE\x00\x00"
          # FF FE 00 00  UTF-32, little-endian BOM
          @result = {'encoding' => "UTF-32LE", 'confidence' => 1.0}
        elsif aBuf[0, 4] == "\x00\x00\xFE\xFF"
          # 00 00 FE FF  UTF-32, big-endian BOM
          @result = {'encoding' => "UTF-32BE", 'confidence' => 1.0}
        elsif aBuf[0, 4] == "\xFE\xFF\x00\x00"
          # FE FF 00 00  UCS-4, unusual octet order BOM (3412)
          @result = {'encoding' => "X-ISO-10646-UCS-4-3412", 'confidence' => 1.0}
        elsif aBuf[0, 4] == "\x00\x00\xFF\xFE"
          # 00 00 FF FE  UCS-4, unusual octet order BOM (2143)
          @result = {'encoding' =>  "X-ISO-10646-UCS-4-2143", 'confidence' =>  1.0}
        elsif aBuf[0, 2] == "\xFF\xFE"
          # FF FE  UTF-16, little endian BOM
          @result = {'encoding' =>  "UTF-16LE", 'confidence' =>  1.0}
        elsif aBuf[0, 2] == "\xFE\xFF"
          # FE FF  UTF-16, big endian BOM
          @result = {'encoding' =>  "UTF-16BE", 'confidence' =>  1.0}
        elsif aBuf[0, 3] == "\x2B\x2F\x76" && ["\x38", "\x39", "\x2B", "\x2F"].include?(aBuf[3, 1])
          # NOTE: Ruby only includes "dummy" support for UTF-7.
          # A Ruby UTF-7 string can't have methods called on it, nor can it be converted to anything else, but "BINARY"/"ASCII-8BIT".
          # Still, this doesn't make detection useless, as UTF-7 encodings exist in the wild, and the scenario may need to be handled.
          # 2B 2F 76 38  UTF-7
          # 2B 2F 76 39  UTF-7
          # 2B 2F 76 2B  UTF-7
          # 2B 2F 76 2F  UTF-7
          # 2B 2F 76 38 2D  UTF-7 with no following character (empty string)
          @result = {'encoding' =>  "UTF-7", 'confidence' =>  0.99}
        end
      end

      @gotData = true
      if @result['encoding'] and (@result['confidence'] > 0.0)
        @done = true
        return
      end
      if @inputState == EPureAscii
        if @highBitDetector =~ (aBuf)
          @inputState = EHighbyte
        elsif (@inputState == EPureAscii) and @escDetector =~ (@lastChar + aBuf)
          @inputState = EEscAscii
        end
      end

      @lastChar = aBuf[-1, 1]
      if @inputState == EEscAscii
        if !@escCharSetProber
          @escCharSetProber = EscCharSetProber.new()
        end
        if @escCharSetProber.feed(aBuf) == EFoundIt
          @result = {'encoding' =>  @escCharSetProber.get_charset_name(),
            'confidence' =>  @escCharSetProber.get_confidence()
          }
          @done = true
        end
      elsif @inputState == EHighbyte
        if @charSetProbers.nil? || @charSetProbers.empty?
          @charSetProbers = [MBCSGroupProber.new(), SBCSGroupProber.new(), Latin1Prober.new()]
        end
        for prober in @charSetProbers
          if prober.feed(aBuf) == EFoundIt
            @result = {'encoding' =>  prober.get_charset_name(),
              'confidence' =>  prober.get_confidence()}
            @done = true
            break
          end
        end
      end

    end

    def close
      return if @done
      if !@gotData
        $stderr << "no data received!\n" if $debug
        return
      end
      @done = true

      if @inputState == EPureAscii
        @result = {'encoding' => 'ascii', 'confidence' => 1.0}
        return @result
      end

      if @inputState == EHighbyte
        confidences = {}
        @charSetProbers.each{ |prober| confidences[prober] = prober.get_confidence }
        maxProber = @charSetProbers.max{ |a,b| confidences[a] <=> confidences[b] }
        if maxProber and maxProber.get_confidence > MINIMUM_THRESHOLD
          @result = {'encoding' =>  maxProber.get_charset_name(),
            'confidence' =>  maxProber.get_confidence()}
          return @result
        end
      end

      if $debug
        $stderr << "no probers hit minimum threshhold\n" if $debug
        for prober in @charSetProbers[0].probers
          next if !prober
          $stderr << "#{prober.get_charset_name} confidence = #{prober.get_confidence}\n" if $debug
        end
      end
    end
  end
end
