######################## BEGIN LICENSE BLOCK ########################
# The Original Code is Mozilla Communicator client code.
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
  class CharSetGroupProber < CharSetProber
    attr_accessor :probers
    def initialize
      super
      @activeNum = 0
      @probers = []
      @bestGuessProber = nil
    end

    def reset
      super
      @activeNum = 0

      for prober in @probers
        if prober
          prober.reset()
          prober.active = true
          @activeNum += 1
        end
      end
      @bestGuessProber = nil
    end

    def get_charset_name
      if !@bestGuessProber
        get_confidence()
        if !@bestGuessProber
          return nil
        end
      end
      return @bestGuessProber.get_charset_name()
    end

    def feed(aBuf)
      for prober in @probers
        next unless prober
        next unless prober.active
        st = prober.feed(aBuf)
        next unless st
        if st == EFoundIt
          @bestGuessProber = prober
          return get_state()
        elsif st == ENotMe
          prober.active = false
          @activeNum -= 1
          if @activeNum <= 0
            @state = ENotMe
            return get_state()
          end
        end
      end
      return get_state()
    end

    def get_confidence()
      st = get_state()
      if st == EFoundIt
        return 0.99
      elsif st == ENotMe
        return 0.01
      end
      bestConf = 0.0
      @bestGuessProber = nil
      for prober in @probers
        next unless prober
        unless prober.active
          $stderr << "#{prober.get_charset_name()} not active\n" if $debug
          next
        end
        cf = prober.get_confidence()
        $stderr << "#{prober.get_charset_name} confidence = #{cf}\n" if $debug
        if bestConf < cf
          bestConf = cf
          @bestGuessProber = prober
        end
      end
      return 0.0 unless @bestGuessProber
      return bestConf
    end
  end
end
