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
  ONE_CHAR_PROB = 0.5

  class UTF8Prober < CharSetProber
    def initialize
      super()
      @codingSM = CodingStateMachine.new(UTF8SMModel)
      reset()
    end

    def reset
      super()
      @codingSM.reset()
      @numOfMBChar = 0
    end

    def get_charset_name
      return "utf-8"
    end

    def feed(aBuf)
      aBuf.each_byte do |b|
        c = b.chr
        codingState = @codingSM.next_state(c)
        if codingState == EError
          @state = ENotMe
          break
        elsif codingState == EItsMe
          @state = EFoundIt
          break
        elsif codingState == EStart
          if @codingSM.get_current_charlen() >= 2
            @numOfMBChar += 1
          end
        end
      end

      if get_state() == EDetecting
        if get_confidence() > SHORTCUT_THRESHOLD
          @state = EFoundIt
        end
      end

      return get_state()
    end

    def get_confidence
      unlike = 0.99
      if @numOfMBChar < 6
        for i in (0...@numOfMBChar)
          unlike = unlike * ONE_CHAR_PROB
        end
        return 1.0 - unlike
      else
        return unlike
      end
    end
  end
end
