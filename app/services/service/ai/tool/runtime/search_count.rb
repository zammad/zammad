# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# How many searches a run has made, the current one included, and the line that says so from the third on: the budget
#   of about three searches for one request stands where the model reads it, in the result. A lookup in a connected
#   system is a search too, counted with the others: the step records a call's start before the tool runs, with the
#   server's name for a connected system's tool, and runs the calls one after the other. The next page of a list is no
#   search of its own, and gets no line: the hint would stop a listing halfway.
class Service::AI::Tool::Runtime::SearchCount
  NOTE_FROM = 3

  # A call refused before its tool ran searched nothing: a tool the step held back, or a name no offered tool has.
  REFUSED = %w[not_loaded unknown_tool].freeze
  NOT_REFUSED = <<~SQL.squish.freeze
    NOT EXISTS (
      SELECT 1 FROM ai_harness_events refusals
      WHERE refusals.run_id = ai_harness_events.run_id
        AND refusals.event_type = 'tool_call_finished'
        AND refusals.payload ->> 'tool_call_id' = ai_harness_events.payload ->> 'tool_call_id'
        AND refusals.payload -> 'content' ->> 'error' IN (:refused)
    )
  SQL

  class << self
    # @param run [AI::Harness::Run, nil]
    # @return [Integer] 0 without a run, as over the MCP server
    def of(run)
      return 0 if run.nil?

      run.events
        .where(event_type: 'tool_call_started')
        .where("payload ->> 'name' IN (?) OR payload ->> 'server_name' IS NOT NULL", searching_tool_names)
        .where("payload -> 'arguments' ->> 'cursor' IS NULL")
        .where(NOT_REFUSED, refused: REFUSED)
        .count
    end

    # A failed search counts as well, so its message carries the line too; the error keeps its code.
    #
    # @param result [Service::AI::Tool::Runtime::Result] a search tool's result
    # @return [Service::AI::Tool::Runtime::Result] with the line from the third search of the run on
    def noted_result(result, run:)
      return Service::AI::Tool::Runtime::Result.ok(result.content, text: noted(result.text, run:)) if result.ok?

      Service::AI::Tool::Runtime::Result.error(result.content[:error], noted(result.content[:message], run:))
    end

    # @param text [String] a search tool's text
    # @return [String] the text, with the line from the third search of the run on
    def noted(text, run:)
      count = of(run)
      return text if count < NOTE_FROM

      "#{text}\n\nThis was search #{count} for this request. Answer now with what you found, and name what you " \
        'searched for; search again only for a part of the request you have not searched yet.'
    end

    private

    def searching_tool_names
      Service::AI::Tool::Runtime::Router.tools.select(&:search?).map(&:tool_name)
    end
  end
end
