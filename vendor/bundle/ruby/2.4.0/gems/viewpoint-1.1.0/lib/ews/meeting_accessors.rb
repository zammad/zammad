module Viewpoint::EWS::MeetingAccessors
  include Viewpoint::EWS

  def accept_meeting(opts)
    ews.create_item({
      message_disposition: 'SendOnly',
      items: [ { accept_item: opts_to_item(opts) } ]
    })
  end

  def decline_meeting(opts)
    ews.create_item({
      message_disposition: 'SendOnly',
      items: [ { decline_item: opts_to_item(opts) } ]
    })
  end

  def tentatively_accept_meeting(opts)
    ews.create_item({
      message_disposition: 'SendOnly',
      items: [ { tentatively_accept_item: opts_to_item(opts) } ]
    })
  end

  private

  def opts_to_item(opts)
    hash = {
      id: opts[:id],
      change_key: opts[:change_key],
      sensitivity: opts[:sensitivity]
    }

    hash[:text] = opts[:text] if opts[:text]
    hash[:body_type] = (opts[:body_type] || 'Text') if opts[:text]

    hash
  end
end
