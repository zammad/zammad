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
  class CodingStateMachine
    attr_accessor :active

    def initialize(sm)
      @model = sm
      @currentBytePos = 0
      @currentCharLen = 0
      reset()
    end

    def reset
      @currentState = EStart
    end

    def next_state(c)
      # for each byte we get its class
      # if it is first byte, we also get byte length
      b = c.bytes.first
      byteCls = @model['classTable'][b]
      if @currentState == EStart
        @currentBytePos = 0
        @currentCharLen = @model['charLenTable'][byteCls]
      end
      # from byte's class and stateTable, we get its next state
      @currentState = @model['stateTable'][@currentState * @model['classFactor'] + byteCls]
      @currentBytePos += 1
      return @currentState
    end

    def get_current_charlen
      return @currentCharLen
    end

    def get_coding_state_machine
      return @model['name']
    end
  end
end
