# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Text

  # Removes quoted content from email text.
  #
  # Handles various email client formats (Gmail, Outlook, Apple Mail, etc.)
  # and multiple languages for attribution lines.
  #
  # Processing order:
  # 1. Detect attribution lines using patterns in attribution_pattern/
  # 2. For attributions followed by > quoted blocks, remove both
  # 3. For attributions without > markers, remove everything after
  # 4. Remove remaining standalone > quoted lines
  # 5. Optionally remove signatures (mobile + standard "-- " delimiter)
  #
  class QuoteRemover

    attr_reader :remove_signatures, :text

    def initialize(text:, remove_signatures: false)
      @text = text
      @remove_signatures = remove_signatures
    end

    def remove
      return text.strip if text.blank?

      lines = text.lines
      lines = process_attributions(lines)
      lines = remove_inline_quotes(lines)
      lines = remove_signatures_from_lines(lines) if remove_signatures
      lines.join.strip
    end

    private

    # Process attribution lines and their associated quoted content
    def process_attributions(lines)
      result = []
      index = 0

      while index < lines.length
        line = lines[index]
        stripped = line.strip

        # Empty lines: keep and continue
        if stripped.empty?
          result << line
          index += 1
          next
        end

        # Check for attribution pattern
        matched_pattern = find_attribution(stripped, lines, index)

        # Regular > quoted lines (not attribution like ">>> Name >>>"): keep and continue
        if stripped.start_with?('>') && !matched_pattern
          result << line
          index += 1
          next
        end

        if matched_pattern
          break if matched_pattern.removes_all_after?

          quote_end = find_quote_block_end(lines, index + 1)
          break if quote_end.nil?

          index = quote_end
        else
          result << line
          index += 1
        end
      end

      result
    end

    # Find which attribution pattern matches, or nil
    def find_attribution(line, lines, index)
      AttributionPattern.find_match(line) ||
        (AttributionPattern::MsHeaderBlock.match_at?(lines, index) && AttributionPattern::MsHeaderBlock)
    end

    # Find where a > quoted block ends, or nil if no quote block follows
    def find_quote_block_end(lines, start_index)
      return nil if start_index >= lines.length

      index = skip_empty_lines(lines, start_index)
      return nil if index >= lines.length
      return nil if !lines[index].strip.start_with?('>')

      index = scan_quote_block(lines, index)
      return nil if !real_content_after?(lines, index)

      index
    end

    # Skip consecutive empty lines
    def skip_empty_lines(lines, start_index)
      index = start_index
      index += 1 while index < lines.length && lines[index].strip.empty?
      index
    end

    # Scan through a > quoted block, returns index after the block
    def scan_quote_block(lines, start_index)
      index = start_index

      while index < lines.length
        stripped = lines[index].strip

        if stripped.start_with?('>')
          index += 1
        elsif stripped.empty?
          # Check if more > lines follow after empty lines
          lookahead = skip_empty_lines(lines, index + 1)
          return skip_empty_lines(lines, index) if lookahead >= lines.length || !lines[lookahead].strip.start_with?('>')

          index = lookahead
        else
          break
        end
      end

      index
    end

    # Check if there's real user content after the given index
    def real_content_after?(lines, start_index)
      (start_index...lines.length).each do |i|
        stripped = lines[i].strip
        next if stripped.empty?
        next if stripped.match?(%r{^\[\d+\]\s*(https?://|mailto:)})
        return false if stripped == '--'

        return true
      end

      false
    end

    # Remove lines that start with > and trailing empty lines after them
    def remove_inline_quotes(lines)
      result = []
      in_quote = false

      lines.each do |line|
        stripped = line.strip

        if stripped.start_with?('>')
          in_quote = true
        elsif in_quote && stripped.empty?
          # Skip empty lines after quote blocks
        else
          in_quote = false
          result << line
        end
      end

      result
    end

    # Remove all signature content from lines
    def remove_signatures_from_lines(lines)
      lines = remove_standard_signatures(lines)
      remove_mobile_signatures(lines)
    end

    # Remove content starting from the signature delimiter "--"
    def remove_standard_signatures(lines)
      delimiter_index = lines.rindex { |line| Signature::Standard.match?(line) }
      return lines if delimiter_index.nil?

      lines[0...delimiter_index]
    end

    # Remove mobile signature lines
    def remove_mobile_signatures(lines)
      lines.reject { |line| Signature::Mobile.match?(line) } # rubocop:disable Style/SelectByRegexp
    end
  end
end
