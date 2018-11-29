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
  SAMPLE_SIZE = 64
  SB_ENOUGH_REL_THRESHOLD = 1024
  POSITIVE_SHORTCUT_THRESHOLD = 0.95
  NEGATIVE_SHORTCUT_THRESHOLD = 0.05
  SYMBOL_CAT_ORDER = 250
  NUMBER_OF_SEQ_CAT = 4
  POSITIVE_CAT = NUMBER_OF_SEQ_CAT - 1
  #NEGATIVE_CAT = 0

  class SingleByteCharSetProber < CharSetProber
    def initialize(model, reversed=false, nameProber=nil)
      super()
      @model = model
      @reversed = reversed # TRUE if we need to reverse every pair in the model lookup
      @nameProber = nameProber # Optional auxiliary prober for name decision
      reset()
    end

    def reset
      super()
      @lastOrder = 255 # char order of last character
      @seqCounters = [0] * NUMBER_OF_SEQ_CAT
      @totalSeqs = 0
      @totalChar = 0
      @freqChar = 0 # characters that fall in our sampling range
    end

    def get_charset_name
      if @nameProber
        return @nameProber.get_charset_name()
      else
        return @model['charsetName']
      end
    end

    def feed(aBuf)
      if !@model['keepEnglishLetter']
        aBuf = filter_without_english_letters(aBuf)
      end
      aLen = aBuf.length
      if aLen == 0
        return get_state()
      end
      aBuf.each_byte do |b|
        c = b.chr
        order = @model['charToOrderMap'][c.bytes.first]
        if order < SYMBOL_CAT_ORDER
          @totalChar += 1
        end
        if order < SAMPLE_SIZE
          @freqChar += 1
          if @lastOrder < SAMPLE_SIZE
            @totalSeqs += 1
            if !@reversed
              @seqCounters[@model['precedenceMatrix'][(@lastOrder * SAMPLE_SIZE) + order]] += 1
            else # reverse the order of the letters in the lookup
              @seqCounters[@model['precedenceMatrix'][(order * SAMPLE_SIZE) + @lastOrder]] += 1
            end
          end
        end
        @lastOrder = order
      end

      if get_state() == EDetecting
        if @totalSeqs > SB_ENOUGH_REL_THRESHOLD
          cf = get_confidence()
          if cf > POSITIVE_SHORTCUT_THRESHOLD
            $stderr << "#{@model['charsetName']} confidence = #{cf}, we have a winner\n" if $debug
            @state = EFoundIt
          elsif cf < NEGATIVE_SHORTCUT_THRESHOLD
            $stderr << "#{@model['charsetName']} confidence = #{cf}, below negative shortcut threshold #{NEGATIVE_SHORTCUT_THRESHOLD}\n" if $debug
            @state = ENotMe
          end
        end
      end

      return get_state()
    end

    def get_confidence
      r = 0.01
      if @totalSeqs > 0
        r = (1.0 * @seqCounters[POSITIVE_CAT]) / @totalSeqs / @model['mTypicalPositiveRatio']
        r = r * @freqChar / @totalChar
        if r >= 1.0
          r = 0.99
        end
      end
      return r
    end
  end
end
