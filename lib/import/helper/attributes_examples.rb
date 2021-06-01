# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module Helper
    class AttributesExamples
      attr_reader :examples, :enough, :max_unkown

      def initialize(&block)
        @max_unkown     = 50
        @no_new_counter = 1
        @examples       = {}
        @known          = []

        # Support both builder styles:
        #
        #   Import::Helper::AttributesExamples.new do
        #     extract(attributes)
        #   end
        #
        # and
        #
        #   Import::Helper::AttributesExamples.new do |extractor|
        #     extractor.extract(attributes)
        #   end
        return if !block

        if block.arity.zero?
          instance_eval(&block)
        else
          yield self
        end
      end

      def extract(attributes)
        unknown = attributes.keys - @known

        return if !unknown?(unknown)

        store(attributes, unknown)

        @known.concat(unknown)
        @no_new_counter = 0
      end

      private

      def unknown?(unknown)
        return true if unknown.present?

        @no_new_counter += 1

        # check max 50 entries with no or no new attributes in a row
        @enough = @no_new_counter != 50

        false
      end

      def store(attributes, unknown)
        unknown.each do |attribute|
          value = attributes[attribute]

          next if value.nil?

          example = value.to_utf8(fallback: :read_as_sanitized_binary)
          example.gsub!(%r{^(.{20,}?).*$}m, '\1...')

          @examples[attribute] = "#{attribute} (e. g. #{example})"
        end
      end

    end
  end
end
