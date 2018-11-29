######################## BEGIN LICENSE BLOCK ########################
# The Original Code is mozilla.org code.
#
# The Initial Developer of the Original Code is
# Netscape Communications Corporation.
# Portions created by the Initial Developer are Copyright (C) 1998
# the Initial Developer. All Rights Reserved.
#
# Contributor(s):
#   Jeff Hodges - port to Ruby
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
  class SJISProber < MultiByteCharSetProber
    def initialize
      super()
      @codingSM = CodingStateMachine.new(SJISSMModel)
      @distributionAnalyzer = SJISDistributionAnalysis.new()
      @contextAnalyzer = SJISContextAnalysis.new()
      reset()
    end

    def reset
      super()
      @contextAnalyzer.reset()
    end

    def get_charset_name
      return "SHIFT_JIS"
    end

    def feed(aBuf)
      aLen = aBuf.length
      for i in (0...aLen)
        codingState = @codingSM.next_state(aBuf[i,1])
        if codingState == EError
          $stderr << "#{get_charset_name} prober hit error at byte #{i}\n" if $debug
          @state = ENotMe
          break
        elsif codingState == EItsMe
          @state = EFoundIt
          break
        elsif codingState == EStart
          charLen = @codingSM.get_current_charlen()
          if i == 0
            @lastChar[1] = aBuf[0, 1]
            @contextAnalyzer.feed(@lastChar[2-charLen, 1], charLen)
            @distributionAnalyzer.feed(@lastChar, charLen)
          else
            @contextAnalyzer.feed(aBuf[i+1-charLen, 2], charLen)
            @distributionAnalyzer.feed(aBuf[i-1, 2], charLen)
          end
        end
      end

      @lastChar[0] = aBuf[aLen-1, 1]

      if get_state() == EDetecting
        if @contextAnalyzer.got_enough_data() and (get_confidence() > SHORTCUT_THRESHOLD)
          @state = EFoundIt
        end
      end

      return get_state()
    end

    def get_confidence
      l = [@contextAnalyzer.get_confidence(), @distributionAnalyzer.get_confidence()]
      return l.max
    end
  end
end
