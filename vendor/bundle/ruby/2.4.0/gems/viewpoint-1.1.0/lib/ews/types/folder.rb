module Viewpoint::EWS::Types
  class Folder
    include Viewpoint::EWS
    include Viewpoint::EWS::Types
    include Viewpoint::EWS::Types::GenericFolder

    FOLDER_KEY_PATHS = {
      :unread_count       => [:unread_count, :text],
    }
    FOLDER_KEY_TYPES = {
      :unread_count       => ->(str){str.to_i},
    }
    FOLDER_KEY_ALIAS = {}

    alias :messages :items

    def unread_messages
      self.items read_unread_restriction
    end

    def read_messages
      self.items read_unread_restriction(true)
    end

    def messages_with_attachments
      opts = {:restriction =>
        {:is_equal_to => [
          {:field_uRI => {:field_uRI=>'item:HasAttachments'}},
          {:field_uRI_or_constant => {:constant => {:value=> true}}}
        ]}
      }
      self.items opts
    end

    private


    def read_unread_restriction(read = false)
      {:restriction =>
        {:is_equal_to => [
          {:field_uRI => {:field_uRI=>'message:IsRead'}},
          {:field_uRI_or_constant => {:constant => {:value=> read}}}
        ]}
      }
    end

    def key_paths
      @key_paths ||= super.merge(FOLDER_KEY_PATHS)
    end

    def key_types
      @key_types ||= super.merge(FOLDER_KEY_TYPES)
    end

    def key_alias
      @key_alias ||= super.merge(FOLDER_KEY_ALIAS)
    end

  end
end
