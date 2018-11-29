=begin
This file is a cotribution to Viewpoint; the Ruby library for Microsoft Exchange Web Services.

Copyright © 2013 Mark McCahill <mark.mccahill@duke.edu>

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

module Viewpoint::EWS::CalendarAccessors
  include Viewpoint::EWS

  def event_busy_type( the_event )
    the_event[:calendar_event][:elems][2][:busy_type][:text]
  end

  def event_start_time( the_event )
    the_event[:calendar_event][:elems][0][:start_time][:text]
  end

  def event_end_time( the_event )
    the_event[:calendar_event][:elems][1][:end_time][:text]
  end

end # Viewpoint::EWS::CalendarAccessors
