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

    OOF_KEY_PATHS = {
      :enabled?   => [:oof_settings, :oof_state],
      :scheduled? => [:oof_settings, :oof_state],
      :duration   => [:oof_settings, :duration],
    }

    OOF_KEY_TYPES = {
      :enabled?   => ->(str){str == :enabled},
      :scheduled? => ->(str){str == :scheduled},
      :duration   => ->(hsh){ hsh[:start_time]..hsh[:end_time] },
    }

    OOF_KEY_ALIAS = {}

  # This represents OutOfOffice settings
  # @see http://msdn.microsoft.com/en-us/library/aa563465.aspx
  class OutOfOffice
    include Viewpoint::EWS
    include Viewpoint::EWS::Types

    attr_reader :user

    # @param [MailboxUser] user
    # @param [Hash] ews_item
    def initialize(user, ews_item)
      @ews =  user.ews
      @user = user
      @ews_item = ews_item
      @changed = false
      simplify!
    end

    def changed?
      @changed
    end

    def save!
      return true unless changed?
      opts = { mailbox: {address: user.email_address} }.merge(@ews_item[:oof_settings])
      resp = @ews.set_user_oof_settings(opts)
      if resp.success?
        @changed = false
        true
      else
        raise SaveFailed, "Could not save #{self.class}. #{resp.code}: #{resp.message}"
      end
    end

    def enable
      return true if enabled?
      @changed = true
      @ews_item[:oof_settings][:oof_state] = :enabled
    end

    def disable
      return true unless enabled? || scheduled?
      @changed = true
      @ews_item[:oof_settings][:oof_state] = :disabled
    end

    # Schedule an out of office.
    # @param [DateTime] start_time
    # @param [DateTime] end_time
    def schedule(start_time, end_time)
      @changed = true
      @ews_item[:oof_settings][:oof_state] = :scheduled
      set_duration start_time, end_time
    end

    # Specify a duration for this Out Of Office setting
    # @param [DateTime] start_time
    # @param [DateTime] end_time
    def set_duration(start_time, end_time)
      @changed = true
      @ews_item[:oof_settings][:duration][:start_time] = start_time
      @ews_item[:oof_settings][:duration][:end_time] = end_time
    end

    # A message to send to internal users
    # @param [String] message
    def internal_reply=(message)
      @changed = true
      @ews_item[:oof_settings][:internal_reply] = message
    end

    # A message to send to external users
    # @param [String] message
    def external_reply=(message)
      @changed = true
      @ews_item[:oof_settings][:external_reply] = message
    end


private

    def key_paths
      @key_paths ||= super.merge(OOF_KEY_PATHS)
    end

    def key_types
      @key_types ||= super.merge(OOF_KEY_TYPES)
    end

    def key_alias
      @key_alias ||= super.merge(OOF_KEY_ALIAS)
    end

    def simplify!
      oof_settings = @ews_item[:oof_settings][:elems].inject(:merge)
      oof_settings[:oof_state] = oof_settings[:oof_state][:text].downcase.to_sym
      oof_settings[:external_audience] = oof_settings[:external_audience][:text]
      if oof_settings[:duration]
        dur = oof_settings[:duration][:elems].inject(:merge)
        oof_settings[:duration] = {
          start_time: DateTime.iso8601(dur[:start_time][:text]),
          end_time:   DateTime.iso8601(dur[:end_time][:text])
        }
      end
      oof_settings[:internal_reply] = oof_settings[:internal_reply][:elems][0][:message][:text] || ""
      oof_settings[:external_reply] = oof_settings[:external_reply][:elems][0][:message][:text] || ""
      @ews_item[:oof_settings] = oof_settings
      @ews_item[:allow_external_oof] = @ews_item[:allow_external_oof][:text]
    end

  end #OutOfOffice

end
