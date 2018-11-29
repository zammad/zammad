require 'hashie'

module ZendeskAPI
  # @private
  class SilentMash < Hashie::Mash
    disable_warnings
  end
end
