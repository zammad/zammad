# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The cursor of a list's next page, as MCP servers hand them out: an opaque string, so that no caller counts on its
#   form. It holds the position and a fingerprint of the list it belongs to, so that a cursor passed with other
#   arguments than its list's is refused instead of paging another list from a position that means nothing there.
class Service::AI::Tool::Runtime::Cursor
  # @param offset [Integer] where the next page starts
  # @param scope [Hash] what makes the list: the arguments of the call, apart from the cursor and the page size
  # @return [String]
  def self.encode(offset:, scope:)
    Base64.urlsafe_encode64({ offset:, scope: fingerprint(scope) }.to_json, padding: false)
  end

  # @param cursor [String, nil] as the caller passed it
  # @return [Integer, nil] 0 without a cursor, nil for one that was not given for this list
  def self.decode(cursor, scope:)
    return 0 if cursor.nil?

    data = JSON.parse(Base64.urlsafe_decode64(cursor))
    return if !data.is_a?(Hash) || data['scope'] != fingerprint(scope)

    offset = data['offset']
    offset if offset.is_a?(Integer) && !offset.negative?
  rescue ArgumentError, JSON::ParserError
    nil
  end

  def self.fingerprint(scope)
    Digest::SHA256.hexdigest(scope.to_json).first(16)
  end
  private_class_method :fingerprint
end
