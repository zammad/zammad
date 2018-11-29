module Viewpoint::EWS::Types
  module Item
    include Viewpoint::EWS
    include Viewpoint::EWS::Types
    include ItemFieldUriMap

    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      def init_simple_item(ews, id, change_key = nil, parent = nil)
        ews_item = {item_id: {attribs: {id: id, change_key: change_key}}}
        self.new ews, ews_item, parent
      end
    end

    ITEM_KEY_PATHS = {
      item_id:        [:item_id, :attribs],
      id:             [:item_id, :attribs, :id],
      change_key:     [:item_id, :attribs, :change_key],
      subject:        [:subject, :text],
      sensitivity:    [:sensitivity, :text],
      size:           [:size, :text],
      date_time_sent: [:date_time_sent, :text],
      date_time_created: [:date_time_created, :text],
      last_modified_time: [:last_modified_time, :text],
      mime_content: [:mime_content, :text],
      has_attachments?:[:has_attachments, :text],
      is_associated?: [:is_associated, :text],
      is_read?:       [:is_read, :text],
      is_draft?:      [:is_draft, :text],
      is_submitted?:  [:is_submitted, :text],
      conversation_id:[:conversation_id, :attribs, :id],
      categories:     [:categories, :elems],
      internet_message_id:[:internet_message_id, :text],
      internet_message_headers:[:internet_message_headers, :elems],
      sender:         [:sender, :elems, 0, :mailbox, :elems],
      from:           [:from, :elems, 0, :mailbox, :elems],
      to_recipients:  [:to_recipients, :elems],
      cc_recipients:  [:cc_recipients, :elems],
      attachments:    [:attachments, :elems],
      importance:     [:importance, :text],
      conversation_index:     [:conversation_index, :text],
      conversation_topic:     [:conversation_topic, :text],
      body_type: [:body, :attribs, :body_type],
      body: [:body, :text]
    }

    ITEM_KEY_TYPES = {
      size:               ->(str){str.to_i},
      date_time_sent:     ->(str){DateTime.parse(str)},
      date_time_created:  ->(str){DateTime.parse(str)},
      last_modified_time: ->(str){DateTime.parse(str)},
      has_attachments?:   ->(str){str.downcase == 'true'},
      is_associated?:     ->(str){str.downcase == 'true'},
      is_read?:           ->(str){str.downcase == 'true'},
      is_draft?:          ->(str){str.downcase == 'true'},
      is_submitted?:      ->(str){str.downcase == 'true'},
      categories:         ->(obj){obj.collect{|s| s[:string][:text]}},
      internet_message_headers: ->(obj){obj.collect{|h|
          {h[:internet_message_header][:attribs][:header_name] =>
            h[:internet_message_header][:text]} } },
      sender: :build_mailbox_user,
      from:   :build_mailbox_user,
      to_recipients:   :build_mailbox_users,
      cc_recipients:   :build_mailbox_users,
      attachments: :build_attachments,
    }

    ITEM_KEY_ALIAS = {
      :read?        => :is_read?,
      :draft?       => :is_draft?,
      :submitted?   => :is_submitted?,
      :associated?  => :is_associated?,
    }

    attr_reader :ews_item, :parent

    # @param ews [SOAP::ExchangeWebService] the EWS reference
    # @param ews_item [Hash] the EWS parsed response document
    # @param parent [GenericFolder] an optional parent object
    def initialize(ews, ews_item, parent = nil)
      super(ews, ews_item)
      @parent = parent
      @body_type = false
      simplify!
      @new_file_attachments = []
      @new_item_attachments = []
      @new_inline_attachments = []
    end

    # Specify a body_type to fetch this item with if it hasn't already been fetched.
    # @param body_type [String, Symbol, FalseClass] must be :best, :text, or
    #   :html. You can also set it to false to make it use the default.
    def default_body_type=(body_type)
      @body_type = body_type
    end

    def delete!(deltype = :hard, opts = {})
      opts = {
        :delete_type => delete_type(deltype),
        :item_ids => [{:item_id => {:id => id}}]
      }.merge(opts)

      resp = @ews.delete_item(opts)
      rmsg = resp.response_messages[0]
      unless rmsg.success?
        raise EwsError, "Could not delete #{self.class}. #{rmsg.response_code}: #{rmsg.message_text}"
      end
      true
    end

    def recycle!
      delete! :recycle
    end

    def get_all_properties!
      @ews_item = get_item(base_shape: 'AllProperties')
      simplify!
    end

    # Mark an item as read
    def mark_read!
      update_is_read_status true
    end

    # Mark an item as unread
    def mark_unread!
      update_is_read_status false
    end

    # Move this item to a new folder
    # @param [String,Symbol,GenericFolder] new_folder The new folder to move it to. This should
    #   be a subclass of GenericFolder, a DistinguishedFolderId (must me a Symbol) or a FolderId (String)
    # @return [String] the new Id of the moved item
    def move!(new_folder)
      new_folder = new_folder.id if new_folder.kind_of?(GenericFolder)
      move_opts = {
        :to_folder_id => {:id => new_folder},
        :item_ids => [{:item_id => {:id => self.id}}]
      }
      resp = @ews.move_item(move_opts)
      rmsg = resp.response_messages[0]

      if rmsg.success?
        obj = rmsg.items.first
        itype = obj.keys.first
        obj[itype][:elems][0][:item_id][:attribs][:id]
      else
        raise EwsError, "Could not move item. #{resp.code}: #{resp.message}"
      end
    end

    # Copy this item to a new folder
    # @param [String,Symbol,GenericFolder] new_folder The new folder to move it to. This should
    #   be a subclass of GenericFolder, a DistinguishedFolderId (must me a Symbol) or a FolderId (String)
    # @return [String] the new Id of the copied item
    def copy(new_folder)
      new_folder = new_folder.id if new_folder.kind_of?(GenericFolder)
      copy_opts = {
        :to_folder_id => {:id => new_folder},
        :item_ids => [{:item_id => {:id => self.id}}]
      }
      resp = @ews.copy_item(copy_opts)
      rmsg = resp.response_messages[0]

      if rmsg.success?
        obj = rmsg.items.first
        itype = obj.keys.first
        obj[itype][:elems][0][:item_id][:attribs][:id]
      else
        raise EwsError, "Could not copy item. #{rmsg.response_code}: #{rmsg.message_text}"
      end
    end

    def add_file_attachment(file)
      fa = OpenStruct.new
      fa.name     = File.basename(file.path)
      fa.content  = Base64.encode64(file.read)
      @new_file_attachments << fa
    end

    def add_item_attachment(other_item, name = nil)
      ia = OpenStruct.new
      ia.name = (name ? name : other_item.subject)
      ia.item = {id: other_item.id, change_key: other_item.change_key}
      @new_item_attachments << ia
    end

    def add_inline_attachment(file)
      fi = OpenStruct.new
      fi.name     = File.basename(file.path)
      fi.content  = Base64.encode64(file.read)
      @new_inline_attachments << fi
    end

    def submit!
      if draft?
        submit_attachments!
        resp = ews.send_item(item_ids: [{item_id: {id: self.id, change_key: self.change_key}}])
        rm = resp.response_messages[0]
        if rm.success?
          true
        else
          raise EwsSendItemError, "#{rm.code}: #{rm.message_text}"
        end
      else
        false
      end
    end

    def submit_attachments!
      return false unless draft? && !(@new_file_attachments.empty? && @new_item_attachments.empty? && @new_inline_attachments.empty?)

      opts = {
        parent_id: {id: self.id, change_key: self.change_key},
        files: @new_file_attachments,
        items: @new_item_attachments,
        inline_files: @new_inline_attachments
      }
      resp = ews.create_attachment(opts)
      set_change_key resp.response_messages[0].attachments[0].parent_change_key
      @new_file_attachments = []
      @new_item_attachments = []
      @new_inline_attachments = []
    end

    # If you want to add to the body set #new_body_content. If you set #body
    # it will override the body that is there.
    # @see MessageAccessors#send_message for options
    #   additional options:
    #     :new_body_content, :new_body_type
    # @example
    #   item.forward do |i|
    #     i.new_body_content = "Add this to the top"
    #     i.to_recipients << 'test@example.com'
    #   end
    def forward(opts = {})
      msg = Template::ForwardItem.new opts.clone
      yield msg if block_given?
      msg.reference_item_id = {id: self.id, change_key: self.change_key}
      dispatch_create_item! msg
    end

    def reply_to(opts = {})
      msg = Template::ReplyToItem.new opts.clone
      yield msg if block_given?
      msg.reference_item_id = {id: self.id, change_key: self.change_key}
      dispatch_create_item! msg
    end

    def reply_to_all(opts = {})
      msg = Template::ReplyToItem.new opts.clone
      yield msg if block_given?
      msg.reference_item_id = {id: self.id, change_key: self.change_key}
      msg.ews_type = :reply_all_to_item
      dispatch_create_item! msg
    end


    private

    def key_paths
      super.merge(ITEM_KEY_PATHS)
    end

    def key_types
      super.merge(ITEM_KEY_TYPES)
    end

    def key_alias
      super.merge(ITEM_KEY_ALIAS)
    end

    def update_is_read_status(read)
      field = :is_read
      opts = {item_changes:
        [
          { item_id: {id: id, change_key: change_key},
            updates: [
              {set_item_field: {field_uRI: {field_uRI: FIELD_URIS[field][:text]},
                message: {sub_elements: [{field => {text: read}}]}}}
            ]
          }
        ]
      }
      resp = ews.update_item({conflict_resolution: 'AutoResolve'}.merge(opts))
      rmsg = resp.response_messages[0]
      unless rmsg.success?
        raise EwsError, "#{rmsg.response_code}: #{rmsg.message_text}"
      end
      true
    end

    def simplify!
      return unless @ews_item.has_key?(:elems)
      @ews_item = @ews_item[:elems].inject({}) do |o,i|
        key = i.keys.first
        if o.has_key?(key)
          if o[key].is_a?(Array)
            o[key] << i[key]
          else
            o[key] = [o.delete(key), i[key]]
          end
        else
          o[key] = i[key]
        end
        o
      end
    end

    # Get a specific item by its ID.
    # @param [Hash] opts Misc options to control request
    # @option opts [String] :base_shape IdOnly/Default/AllProperties
    # @raise [EwsError] raised when the backend SOAP method returns an error.
    def get_item(opts = {})
      args = get_item_args(opts)
      resp = ews.get_item(args)
      get_item_parser(resp)
    end

    # Build up the arguements for #get_item
    # @todo: should we really pass the ChangeKey or do we want the freshest obj?
    def get_item_args(opts)
      opts[:base_shape] ||= 'Default'
      default_args = {
        item_shape: {base_shape: opts[:base_shape]},
        item_ids:   [{item_id:{id: id, change_key: change_key}}]
      }
      default_args[:item_shape][:body_type] = @body_type if @body_type
      default_args
    end

    def get_item_parser(resp)
      rm = resp.response_messages[0]
      if(rm.status == 'Success')
        rm.items[0].values.first
      else
        raise EwsError, "Could not retrieve #{self.class}. #{rm.code}: #{rm.message_text}"
      end
    end

    # Map a delete type to what EWS expects
    # @param [Symbol] type. Must be :hard, :soft, or :recycle
    def delete_type(type)
      case type
      when :hard then 'HardDelete'
      when :soft then 'SoftDelete'
      when :recycle then 'MoveToDeletedItems'
      else 'MoveToDeletedItems'
      end
    end

    def build_deleted_occurrences(occurrences)
      occurrences.collect{|a| DateTime.parse a[:deleted_occurrence][:elems][0][:start][:text]}
    end

    def build_modified_occurrences(occurrences)
      {}.tap do |h|
        occurrences.collect do |a|
          elems = a[:occurrence][:elems]

          h[DateTime.parse(elems.find{|e| e[:original_start]}[:original_start][:text])] = {
            start: elems.find{|e| e[:start]}[:start][:text],
            end: elems.find{|e| e[:end]}[:end][:text]
          }
        end
      end
    end

    def build_mailbox_user(mbox_ews)
      MailboxUser.new(ews, mbox_ews)
    end

    def build_mailbox_users(users)
      return [] if users.nil?
      users.collect{|u| build_mailbox_user(u[:mailbox][:elems])}
    end

    def build_attendees_users(users)
      return [] if users.nil?
      users.collect do |u|
        u[:attendee][:elems].collect do |a|
          build_mailbox_user(a[:mailbox][:elems]) if a[:mailbox]
        end
      end.flatten.compact
    end

    def build_attachments(attachments)
      return [] if attachments.nil?
      attachments.collect do |att|
        key = att.keys.first
        class_by_name(key).new(self, att[key])
      end
    end

    def set_change_key(ck)
      p = resolve_key_path(ews_item, key_paths[:change_key][0..-2])
      p[:change_key] = ck
    end

    # Handles the CreateItem call for Forward, ReplyTo, and ReplyAllTo
    # It will handle the neccessary actions for adding attachments.
    def dispatch_create_item!(msg)
      if msg.has_attachments?
        draft = msg.draft
        msg.draft = true
        resp = validate_created_item(ews.create_item(msg.to_ews))
        msg.file_attachments.each do |f|
          next unless f.kind_of?(File)
          resp.add_file_attachment(f)
        end
        if draft
          resp.submit_attachments!
          resp
        else
          resp.submit!
        end
      else
        resp = ews.create_item(msg.to_ews)
        validate_created_item resp
      end
    end

    # validate the CreateItem response.
    # @return [Boolean, Item] returns true if items is empty and status is
    #   "Success" if items is not empty it will return the first Item since
    #   we are only dealing with single items here.
    # @raise EwsCreateItemError on failure
    def validate_created_item(response)
      msg = response.response_messages[0]

      if(msg.status == 'Success')
        msg.items.empty? ? true : parse_created_item(msg.items.first)
      else
        raise EwsCreateItemError, "#{msg.code}: #{msg.message_text}"
      end
    end

    def parse_created_item(msg)
      mtype = msg.keys.first
      message = class_by_name(mtype).new(ews, msg[mtype])
    end

  end
end
