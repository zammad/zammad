# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# How every tool shows what it returns, so that the model meets each kind of object in one form whichever tool
#   returned it: a row — one line of facts, and the object's title below it — and texts, each marked with its source
#   and cut to a length. Each part has the same facts twice: in the content for the UI, which an MCP client may also
#   hand its model, and in the text for the model. A class per kind of object builds its parts from these, such as
#   Service::AI::Tool::Output::Ticket.
class Service::AI::Tool::Output
  Part = Data.define(:content, :text)

  # A text as far as it is shown, with a note on how much of it that is where it is cut.
  Cut = Data.define(:text, :truncated, :part, :full_length, :note)

  # How much text before a match a passage keeps, so that a long text shows where the match stands.
  PASSAGE_LEAD = 100

  # What stands for the rest of a cut text.
  CUT_OMISSION = ' …'.freeze

  class << self
    # The kinds of object the tools return as rows, each named by the type its class's schema fixes.
    #
    # @return [Array<String>]
    def row_types
      descendants.filter_map { |output| output::SCHEMA.dig(:properties, :type, :const) if output.const_defined?(:SCHEMA, false) }.uniq
    end

    # In the system's time zone, as in the context block of a run, and as a time field reads.
    def time(value)
      Service::EntityAttribute::Type::Timestamp.format(value)
    end

    # The time zone of every time a tool shows.
    def time_zone
      Service::EntityAttribute::Type::Timestamp.time_zone
    end

    # How long each of several texts may be when they share a budget: an even share each, and what a shorter text
    #   leaves passes on to the longer ones.
    #
    # @param lengths [Array<Integer>] the texts' full lengths
    # @return [Array<Integer>] each text's length, in the order given
    def shared_lengths(lengths, budget:)
      remaining = budget
      shares    = Array.new(lengths.size)

      lengths.each_with_index.sort_by(&:first).each_with_index do |(length, index), rank|
        shares[index] = remaining / (lengths.size - rank)
        remaining    -= [length, shares[index]].min
      end

      shares
    end

    # From the word before the first match, so that a long text shows where the match stands instead of its start; nil
    #   where the match is near enough to the start to show it. With the length shown, the passage comes cut to it, so
    #   that the match stays in it: at a word boundary after the match, else within the word.
    #
    # @param pattern [Regexp] what was searched for
    # @param lead [Integer] how much text before the match the passage keeps, at most
    # @param length [Integer, nil] how much of the passage is shown
    # @return [String, nil]
    def passage_at(text, pattern, lead: PASSAGE_LEAD, length: nil)
      match = text.match(pattern)
      return if match.nil?

      position = match.begin(0)
      lead     = lead.clamp(0, [length - match[0].length - (length / 4), 0].max) if length
      return if position <= lead && length.nil?

      start = position <= lead ? 0 : passage_start(text, position, lead)
      return text[start..] if length.nil?

      cut_keeping(text[start..], match.end(0) - start, length)
    end

    private

    def passage_start(text, position, lead)
      space = text.index(%r{\s}, position - lead)

      space && space < position ? space + 1 : position
    end

    # As #cut cuts, at the last space that fits, but not before the given end: then within the word.
    def cut_keeping(text, keep_until, length)
      return text if text.length <= length

      stop = length - CUT_OMISSION.length
      cut  = text.rindex(' ', stop)
      cut  = stop if cut.nil? || cut < keep_until

      "#{text[0, cut]}#{CUT_OMISSION}"
    end

    def build_part(content:, text:)
      Part.new(content:, text:)
    end

    # A title with a line break would otherwise start a line of its own.
    #
    # @param facts [Array<String, nil>] the line's facts, nil for one the object does not have
    def build_row(content:, facts:, title:, source:)
      build_part(
        content:,
        text:    [
          AI::PromptText.xml_text(facts.compact.join(' · ').squish),
          AI::PromptText.marked_text(title, source:, field: 'title'),
        ].join("\n"),
      )
    end

    # The whole text where it fits the length, else the passage that matched where there is one, or the start.
    #
    # @param passage [String, nil] the part of the text that matched a search
    def cut(text, length:, passage: nil)
      return Cut.new(text:, truncated: false, part: nil, full_length: nil, note: nil) if text.length <= length

      part  = passage.present? ? 'passage' : 'start'
      shown = (passage.presence || text).truncate(length, separator: ' ', omission: CUT_OMISSION)
      note  = "#{'the passage that matched, ' if part == 'passage'}#{delimited(shown.length)} of #{delimited(text.length)} characters shown"

      Cut.new(text: shown, truncated: true, part:, full_length: text.length, note:)
    end

    def delimited(number)
      ActiveSupport::NumberHelper.number_to_delimited(number)
    end
  end
end
