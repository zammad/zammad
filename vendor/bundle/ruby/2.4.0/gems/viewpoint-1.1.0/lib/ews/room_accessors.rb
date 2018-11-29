=begin
  This file is part of Viewpoint; the Ruby library for Microsoft Exchange Web Services.

  Copyright © 2013 Camille Baldock <viewpoint@camillebaldock.co.uk>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
=end

module Viewpoint::EWS::RoomAccessors
  include Viewpoint::EWS

  # Gets the rooms that are available within the specified room distribution list
  # @see http://msdn.microsoft.com/en-us/library/dd899415.aspx
  # @param [String] roomDistributionList
  def get_rooms(roomDistributionList)
    resp = ews.get_rooms(roomDistributionList)
    get_rooms_parser(resp)
  end

  def room_name( room )
    room[:room][:elems][:id][:elems][0][:name][:text]
  end

  def room_email( room )
    room[:room][:elems][:id][:elems][1][:email_address][:text]
  end

  private

  def get_rooms_parser(resp)
    if resp.success?
      resp
    else
      raise EwsError, "GetRooms produced an error: #{resp.code}: #{resp.message}"
    end
  end

end # Viewpoint::EWS::RoomAccessors