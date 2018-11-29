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

module Viewpoint::EWS::Types

  # This represents a Mailbox object in the Exchange data store
  # @see http://msdn.microsoft.com/en-us/library/aa565036.aspx MSDN docs
  # @todo Design a Class method that resolves to an Array of MailboxUsers
  class MailboxUser
    include Viewpoint::EWS
    include Viewpoint::EWS::Types

    MAILBOX_KEY_PATHS = {
      name: [:name],
      email_address: [:email_address],
    }
    MAILBOX_KEY_TYPES = {}
    MAILBOX_KEY_ALIAS = {
      email: :email_address,
    }

    def initialize(ews, mbox_user)
      @ews = ews
      @ews_item = mbox_user
      simplify!
    end

    def out_of_office_settings
      mailbox = {:address => self.email_address}
      resp = @ews.get_user_oof_settings(mailbox)
      ewsi = resp.response.clone
      ewsi.delete(:response_message)
      return OutOfOffice.new(self,ewsi)
      s = resp[:oof_settings]
      @oof_state = s[:oof_state][:text]
      @oof_ext_audience = s[:external_audience][:text]
      @oof_start = DateTime.parse(s[:duration][:start_time][:text])
      @oof_end = DateTime.parse(s[:duration][:end_time][:text])
      @oof_internal_reply = s[:internal_reply][:message][:text]
      @oof_external_reply = s[:internal_reply][:message][:text]
      true
    end

    # Get information about when the user with the given email address is available.
    # @param [String] email_address The email address of the person to find availability for.
    # @param [DateTime] start_time The start of the time range to check as an xs:dateTime.
    # @param [DateTime] end_time The end of the time range to check as an xs:dateTime.
    # @see http://msdn.microsoft.com/en-us/library/aa563800(v=exchg.140)
    def get_user_availability(email_address, start_time, end_time)
      opts = {
        mailbox_data: [ :email =>{:address => email_address} ],
        free_busy_view_options: {
        time_window: {start_time: start_time, end_time: end_time},
      }
      }
      resp = (Viewpoint::EWS::EWS.instance).ews.get_user_availability(opts)
      if(resp.status == 'Success')
        return resp.items
      else
        raise EwsError, "GetUserAvailability produced an error: #{resp.code}: #{resp.message}"
      end
    end

    # Adds one or more delegates to a principal's mailbox and sets specific access permissions
    # @see http://msdn.microsoft.com/en-us/library/bb856527.aspx
    #
    # @param [String,MailboxUser] delegate_email The user you would like to give delegate access to.
    #   This can either be a simple String e-mail address or you can pass in a MailboxUser object.
    # @param [Hash] permissions A hash of folder type keys and permission type values. An example
    #   would be {:calendar_folder_permission_level => 'Editor'}.  Possible keys are:
    #   :calendar_folder_permission_level, :tasks_folder_permission_level, :inbox_folder_permission_level
    #   :contacts_folder_permission_level, :notes_folder_permission_level, :journal_folder_permission_level
    #   and possible values are:  None/Editor/Reviewer/Author/Custom
    # @return [true] This method either returns true or raises an error with the message
    #   as to why this operation did not succeed.
    def add_delegate!(delegate_email, permissions)
      # Use a new hash so the passed hash is not modified in case we are in a loop.
      # Thanks to Markus Roberts for pointing this out.
      formatted_perms = {}
      # Modify permissions so we can pass it to the builders
      permissions.each_pair do |k,v|
        formatted_perms[k] = {:text => v}
      end

      resp = (Viewpoint::EWS::EWS.instance).ews.add_delegate(self.email_address, delegate_email, formatted_perms)
      if(resp.status == 'Success')
        return true
      else
        raise EwsError, "Could not add delegate access for user #{delegate_email}: #{resp.code}, #{resp.message}"
      end
    end

    def update_delegate!(delegate_email, permissions)
      # Modify permissions so we can pass it to the builders
      formatted_perms = {}
      permissions.each_pair do |k,v|
        formatted_perms[k] = {:text => v}
      end

      resp = (Viewpoint::EWS::EWS.instance).ews.update_delegate(self.email_address, delegate_email, formatted_perms)
      if(resp.status == 'Success')
        return true
      else
        raise EwsError, "Could not update delegate access for user #{delegate_email}: #{resp.code}, #{resp.message}"
      end
    end

    def get_delegate_info()
      resp = (Viewpoint::EWS::EWS.instance).ews.get_delegate(self.email_address)
      # if(resp.status == 'Success')
      #   return true
      # else
      #   raise EwsError, "Could not update delegate access for user #{delegate_email}: #{resp.code}, #{resp.message}"
      # end
    end


    private


    def simplify!
      @ews_item = @ews_item.inject({}){|m,o|
        m[o.keys.first] = o.values.first[:text];
        m
      }
    end

    def key_paths
      @key_paths ||= super.merge(MAILBOX_KEY_PATHS)
    end

    def key_types
      @key_types ||= super.merge(MAILBOX_KEY_TYPES)
    end

    def key_alias
      @key_alias ||= super.merge(MAILBOX_KEY_ALIAS)
    end

  end # MailboxUser
end # Viewpoint::EWS::Types
