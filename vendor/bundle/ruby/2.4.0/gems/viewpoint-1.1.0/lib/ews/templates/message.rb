module Viewpoint::EWS
  module Template
    class Message < OpenStruct

      def initialize(opts = {})
        super opts.clone
        init_defaults!
      end

      # Format this object for EWS backend consumption.
      def to_ews
        ews_opts, msg = to_ews_basic
        ews_opts.merge({items: [{message: msg}]})
      end

      def has_attachments?
        !(file_attachments.empty? && item_attachments.empty? && inline_attachments.empty?)
      end


      private


      def init_defaults!
        self.subject ||= nil
        self.body ||= nil
        self.body_type ||= 'Text'
        self.importance ||= 'Normal'
        self.draft ||= false
        self.is_read = true if is_read.nil?
        self.to_recipients ||= []
        self.cc_recipients ||= []
        self.bcc_recipients ||= []
        self.file_attachments ||= []
        self.item_attachments ||= []
        self.inline_attachments ||= []
        self.extended_properties ||= []
      end

      def to_ews_basic
        ews_opts = {}
        ews_opts[:message_disposition] = (draft ? 'SaveOnly' : 'SendAndSaveCopy')

        if saved_item_folder_id
          if saved_item_folder_id.kind_of?(Hash)
            ews_opts[:saved_item_folder_id] = saved_item_folder_id
          else
            ews_opts[:saved_item_folder_id] = {id: saved_item_folder_id}
          end
        end

        msg = {}
        msg[:subject] = subject if subject
        msg[:body] = {text: body, body_type: body_type} if body

        msg[:importance] = importance if importance

        to_r = to_recipients.collect{|r| {mailbox: {email_address: r}}}
        msg[:to_recipients] = to_r unless to_r.empty?

        cc_r = cc_recipients.collect{|r| {mailbox: {email_address: r}}}
        msg[:cc_recipients] = cc_r unless cc_r.empty?

        bcc_r = bcc_recipients.collect{|r| {mailbox: {email_address: r}}}
        msg[:bcc_recipients] = bcc_r unless bcc_r.empty?

        msg[:is_read] = is_read

        msg[:extended_properties] = extended_properties unless extended_properties.empty?

        [ews_opts, msg]
      end

    end
  end
end
