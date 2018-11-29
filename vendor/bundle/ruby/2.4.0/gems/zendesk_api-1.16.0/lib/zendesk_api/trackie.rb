require 'zendesk_api/track_changes'
require 'zendesk_api/silent_mash'

module ZendeskAPI
  # @private
  class Trackie < SilentMash
    include ZendeskAPI::TrackChanges

    def size
      self['size']
    end
  end
end
