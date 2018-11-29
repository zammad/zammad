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

# This module defines some constants and other niceties to make available to
# the underlying SOAP classes and modules that do the actual work.
module Viewpoint
  module EWS
    module SOAP

      # CONSTANTS

      NS_SOAP         = 'soap'.freeze
      NS_EWS_TYPES    = 't'.freeze
      NS_EWS_MESSAGES = 'm'.freeze
      NAMESPACES = {
        "xmlns:#{NS_SOAP}"         => 'http://schemas.xmlsoap.org/soap/envelope/',
        "xmlns:#{NS_EWS_TYPES}"    => 'http://schemas.microsoft.com/exchange/services/2006/types',
        "xmlns:#{NS_EWS_MESSAGES}" => 'http://schemas.microsoft.com/exchange/services/2006/messages',
      }.freeze

      # used in ResolveNames to determine where names are resolved
      ActiveDirectory         = 'ActiveDirectory'
      ActiveDirectoryContacts = 'ActiveDirectoryContacts'
      Contacts                = 'Contacts'
      ContactsActiveDirectory = 'ContactsActiveDirectory'

      # Target specific Exchange Server versions
      # @see http://msdn.microsoft.com/en-us/library/bb891876(v=exchg.140).aspx
      VERSION_2007      = 'Exchange2007'
      VERSION_2007_SP1  = 'Exchange2007_SP1'
      VERSION_2010      = 'Exchange2010'
      VERSION_2010_SP1  = 'Exchange2010_SP1'
      VERSION_2010_SP2  = 'Exchange2010_SP2'
      VERSION_2013      = 'Exchange2013'
      VERSION_2013_SP1  = 'Exchange2013_SP1'
      VERSION_NONE      = 'none'

      HARD_DELETE = 'HardDelete'
      SOFT_DELETE = 'SoftDelete'
      MOVE_TO_DELETED_ITEMS = 'MoveToDeletedItems'

      def initialize
        @log = Logging.logger[self.class.name.to_s.to_sym]
        @default_ns = NAMESPACES["xmlns:#{NS_EWS_MESSAGES}"]
      end

    end # SOAP
  end # EWS
end # Viewpoint
