######################## BEGIN LICENSE BLOCK ########################
# The Original Code is Mozilla Communicator client code.
# 
# The Initial Developer of the Original Code is
# Netscape Communications Corporation.
# Portions created by the Initial Developer are Copyright (C) 1998
# the Initial Developer. All Rights Reserved.
# 
# Contributor(s):
#   Jeff Hodges
#   Mark Pilgrim - port to Python
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
  ENOUGH_DATA_THRESHOLD = 1024
  SURE_YES = 0.99
  SURE_NO = 0.01

  class CharDistributionAnalysis
    def initialize
      @charToFreqOrder = nil # Mapping table to get frequency order from char order (get from GetOrder())
      @tableSize = nil # Size of above table
      @typicalDistributionRatio = nil # This is a constant value which varies from language to language, used in calculating confidence.  See http://www.mozilla.org/projects/intl/UniversalCharsetDetection.html for further detail.
      reset()
    end

    def reset
      # # """reset analyser, clear any state"""
      @done = false # If this flag is set to constants.True, detection is done and conclusion has been made
      @totalChars = 0 # Total characters encountered
      @freqChars = 0 # The number of characters whose frequency order is less than 512
    end

    def feed(aStr, aCharLen)
      # # """feed a character with known length"""
      if aCharLen == 2
        # we only care about 2-bytes character in our distribution analysis
        order = get_order(aStr)
      else
        order = -1
      end
      if order >= 0
        @totalChars += 1
        # order is valid
        if order < @tableSize
          if 512 > @charToFreqOrder[order]
            @freqChars += 1
          end
        end
      end
    end

    def get_confidence
      # """return confidence based on existing data"""
      # if we didn't receive any character in our consideration range, return negative answer
      if @totalChars <= 0
        return SURE_NO
      end

      if @totalChars != @freqChars
        r = @freqChars / ((@totalChars - @freqChars) * @typicalDistributionRatio)
        if r < SURE_YES
          return r
        end
      end

      # normalize confidence (we don't want to be 100% sure)
      return SURE_YES
    end

    def got_enough_data
      # It is not necessary to receive all data to draw conclusion. For charset detection,
      # certain amount of data is enough
      return @totalChars > ENOUGH_DATA_THRESHOLD
    end

    def get_order(aStr)
      # We do not handle characters based on the original encoding string, but 
      # convert this encoding string to a number, here called order.
      # This allows multiple encodings of a language to share one frequency table.
      return -1
    end
  end

  class EUCTWDistributionAnalysis < CharDistributionAnalysis
    def initialize
      super()
      @charToFreqOrder = EUCTWCharToFreqOrder
      @tableSize = EUCTW_TABLE_SIZE
      @typicalDistributionRatio = EUCTW_TYPICAL_DISTRIBUTION_RATIO
    end

    def get_order(aStr)
      # for euc-TW encoding, we are interested 
      #   first  byte range: 0xc4 -- 0xfe
      #   second byte range: 0xa1 -- 0xfe
      # no validation needed here. State machine has done that
      if aStr[0, 1] >= "\xC4"
        bytes = aStr.bytes.to_a
        return 94 * (bytes[0] - 0xC4) + bytes[1] - 0xA1
      else
        return -1
      end
    end

    def get_confidence
      if @freqChars <= MINIMUM_DATA_THRESHOLD
        return SURE_NO
      end

      super
    end
  end

  class EUCKRDistributionAnalysis < CharDistributionAnalysis
    def initialize
      super()
      @charToFreqOrder = EUCKRCharToFreqOrder
      @tableSize = EUCKR_TABLE_SIZE
      @typicalDistributionRatio = EUCKR_TYPICAL_DISTRIBUTION_RATIO
    end

    def get_order(aStr)
      # for euc-KR encoding, we are interested 
      #   first  byte range: 0xb0 -- 0xfe
      #   second byte range: 0xa1 -- 0xfe
      # no validation needed here. State machine has done that
      if aStr[0, 1] >= "\xB0"
        bytes = aStr.bytes.to_a
        return 94 * (bytes[0] - 0xB0) + bytes[1] - 0xA1
      else
        return -1
      end
    end
  end

  class GB18030DistributionAnalysis < CharDistributionAnalysis
    def initialize
      super()
      @charToFreqOrder = GB18030CharToFreqOrder
      @tableSize = GB18030_TABLE_SIZE
      @typicalDistributionRatio = GB18030_TYPICAL_DISTRIBUTION_RATIO
    end

    def get_order(aStr)
      # for GB18030 encoding, we are interested 
      #  first  byte range: 0xb0 -- 0xfe
      #  second byte range: 0xa1 -- 0xfe
      # no validation needed here. State machine has done that
      if (aStr[0, 1] >= "\xB0") and (aStr[1, 1] >= "\xA1")
        bytes = aStr.bytes.to_a
        return 94 * (bytes[0] - 0xB0) + bytes[1] - 0xA1
      else
        return -1
      end
    end
  end

  class Big5DistributionAnalysis < CharDistributionAnalysis
    def initialize
      super
      @charToFreqOrder = Big5CharToFreqOrder
      @tableSize = BIG5_TABLE_SIZE
      @typicalDistributionRatio = BIG5_TYPICAL_DISTRIBUTION_RATIO
    end

    def get_order(aStr)
      # for big5 encoding, we are interested 
      #   first  byte range: 0xa4 -- 0xfe
      #   second byte range: 0x40 -- 0x7e , 0xa1 -- 0xfe
      # no validation needed here. State machine has done that
      if aStr[0, 1] >= "\xA4"
        bytes = aStr.bytes.to_a
        if aStr[1, 1] >= "\xA1"
          return 157 * (bytes[0] - 0xA4) + bytes[1] - 0xA1 + 63
        else
          return 157 * (bytes[0] - 0xA4) + bytes[1] - 0x40
        end
      else
        return -1
      end
    end
  end

  class SJISDistributionAnalysis < CharDistributionAnalysis
    def initialize
      super()
      @charToFreqOrder = JISCharToFreqOrder
      @tableSize = JIS_TABLE_SIZE
      @typicalDistributionRatio = JIS_TYPICAL_DISTRIBUTION_RATIO
    end

    def get_order(aStr)
      # for sjis encoding, we are interested 
      #   first  byte range: 0x81 -- 0x9f , 0xe0 -- 0xfe
      #   second byte range: 0x40 -- 0x7e,  0x81 -- oxfe
      # no validation needed here. State machine has done that
      bytes = aStr.bytes.to_a
      if (aStr[0, 1] >= "\x81") and (aStr[0, 1] <= "\x9F")
        order = 188 * (bytes[0] - 0x81)
      elsif (aStr[0, 1] >= "\xE0") and (aStr[0, 1] <= "\xEF")
        order = 188 * (bytes[0] - 0xE0 + 31)
      else
        return -1
      end
      order = order + bytes[1] - 0x40
      if aStr[1, 1] > "\x7F"
        order =- 1
      end
      return order
    end
  end

  class EUCJPDistributionAnalysis < CharDistributionAnalysis
    def initialize
      super()
      @charToFreqOrder = JISCharToFreqOrder
      @tableSize = JIS_TABLE_SIZE
      @typicalDistributionRatio = JIS_TYPICAL_DISTRIBUTION_RATIO
    end

    def get_order(aStr)
      # for euc-JP encoding, we are interested 
      #   first  byte range: 0xa0 -- 0xfe
      #   second byte range: 0xa1 -- 0xfe
      # no validation needed here. State machine has done that
      if aStr[0, 1] >= "\xA0"
        bytes = aStr.bytes.to_a
        return 94 * (bytes[0] - 0xA1) + bytes[1] - 0xa1
      else
        return -1
      end
    end
  end
end
