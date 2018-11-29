module Viewpoint::EWS
  module Template
    class ForwardItem < Message

      # Format this object for EWS backend consumption.
      def to_ews
        ews_opts, msg = to_ews_basic
        msg[:reference_item_id] = reference_item_id
        msg[:new_body_content]  = {text: new_body_content, body_type: new_body_type}
        ews_opts.merge({items: [{forward_item: msg}]})
      end

      private


      def init_defaults!
        super
        self.new_body_content ||= ''
        self.new_body_type ||= 'Text'
      end

    end
  end
end
