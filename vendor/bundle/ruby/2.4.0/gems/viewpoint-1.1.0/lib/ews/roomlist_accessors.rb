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

module Viewpoint::EWS::RoomlistAccessors
  include Viewpoint::EWS

  # Gets the room lists that are available within the Exchange organization.
  # @see http://msdn.microsoft.com/en-us/library/dd899416.aspx
  def get_room_lists
    resp = ews.get_room_lists
    get_room_lists_parser(resp)
  end

  def roomlist_name( roomlist )
    roomlist[:address][:elems][:name][:text]
  end

  def roomlist_email( roomlist )
    roomlist[:address][:elems][:email_address][:text]
  end

  private

  def get_room_lists_parser(resp)
    if resp.success?
      resp
    else
      raise EwsError, "GetRoomLists produced an error: #{resp.code}: #{resp.message}"
    end
  end

end # Viewpoint::EWS::RoomlistAccessors