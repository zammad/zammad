=begin
  This file is part of Viewpoint; the Ruby library for Microsoft Exchange Web Services.

  Copyright © 2011 Dan Wanek <dan.wanek@gmail.com>

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
module Viewpoint::EWS

  # Generic Ews Error
  class EwsError < StandardError; end

  # Raise when authentication/authorization issues occur.
  class EwsLoginError < EwsError; end

  class EwsSubscriptionError < EwsError; end

  # Raised when a user tries to query a folder subscription after the
  # subscription has timed out.
  class EwsSubscriptionTimeout < EwsSubscriptionError; end

  # Represents a function in EWS that is not yet implemented in Viewpoint
  class EwsNotImplemented < EwsError; end

  # Raised when an method is called in the wrong way
  class EwsBadArgumentError < EwsError; end

  # Raised when an item that is asked for is not found
  class EwsItemNotFound < EwsError; end

  # Raised when a folder that is asked for is not found
  class EwsFolderNotFound < EwsError; end

  # Raise an Exchange Server version error. This is in case some functionality
  # does not exist in a particular Server version but is called.
  class EwsServerVersionError < EwsError; end

  # Raised when #auto_deepen == false and a method is called for attributes
  # that have not yet been fetched.
  class EwsMinimalObjectError < EwsError; end

  class EwsFrozenObjectError < EwsError; end

  # Failed to save an object back to the EWS store.
  class SaveFailed < EwsError; end

  class EwsCreateItemError < EwsError; end

  class EwsSendItemError < EwsError; end

end # Viewpoint::EWS
