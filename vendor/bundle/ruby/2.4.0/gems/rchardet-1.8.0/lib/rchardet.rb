######################## BEGIN LICENSE BLOCK ########################
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

require 'rchardet/version'
require 'rchardet/charsetprober'
require 'rchardet/mbcharsetprober'

require 'rchardet/big5freq'
require 'rchardet/big5prober'
require 'rchardet/chardistribution'
require 'rchardet/charsetgroupprober'

require 'rchardet/codingstatemachine'
require 'rchardet/constants'
require 'rchardet/escprober'
require 'rchardet/escsm'
require 'rchardet/eucjpprober'
require 'rchardet/euckrfreq'
require 'rchardet/euckrprober'
require 'rchardet/euctwfreq'
require 'rchardet/euctwprober'
require 'rchardet/gb18030freq'
require 'rchardet/gb18030prober'
require 'rchardet/hebrewprober'
require 'rchardet/jisfreq'
require 'rchardet/jpcntx'
require 'rchardet/langbulgarianmodel'
require 'rchardet/langcyrillicmodel'
require 'rchardet/langgreekmodel'
require 'rchardet/langhebrewmodel'
require 'rchardet/langhungarianmodel'
require 'rchardet/langthaimodel'
require 'rchardet/latin1prober'

require 'rchardet/mbcsgroupprober'
require 'rchardet/mbcssm'
require 'rchardet/sbcharsetprober'
require 'rchardet/sbcsgroupprober'
require 'rchardet/sjisprober'
require 'rchardet/universaldetector'
require 'rchardet/utf8prober'

module CharDet
  def CharDet.detect(aBuf)
    aBuf = aBuf.dup.force_encoding(Encoding::BINARY)

    u = UniversalDetector.new
    u.reset
    u.feed(aBuf)
    u.close
    u.result
  end
end
