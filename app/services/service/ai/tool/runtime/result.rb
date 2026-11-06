# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# What a tool call returns: the content goes to the events (for the UI and the sources), the text to the model.
# An error carries a code and a message that tells the model what to do next.
Service::AI::Tool::Runtime::Result = Data.define(:status, :content, :text) do
  def self.ok(content, text: nil)
    new(status: 'ok', content:, text: text || content.to_json)
  end

  # @param texts [Array<String>] marked texts that come after the error, such as what others wrote that the error names
  # @param content [Hash] what the events get beyond the error, which is all the model reads
  def self.error(error, message, texts: [], content: {})
    reply = { error:, message: }

    new(status: 'error', content: reply.merge(content), text: [reply.to_json, *texts].join("\n"))
  end

  def self.confirmation_required(content, text:)
    new(status: 'confirmation_required', content:, text:)
  end

  # @param value [Hash, Service::AI::Tool::Runtime::Result] what a tool's #execute returned
  def self.from(value)
    return value if value.is_a?(self)

    content = value.to_h.deep_symbolize_keys
    return error(content[:error], content[:message]) if content.key?(:error)

    ok(content)
  end

  def ok?
    status == 'ok'
  end
end
