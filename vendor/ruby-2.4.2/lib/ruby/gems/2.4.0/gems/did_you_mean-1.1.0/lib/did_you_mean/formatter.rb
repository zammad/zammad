# frozen-string-literal: true

module DidYouMean
  class Formatter
    def initialize(corrections = [])
      @corrections = corrections
    end

    def to_s
      return "" if @corrections.empty?

      output = "\nDid you mean?  ".dup
      output << @corrections.join("\n               ")
    end
  end
end
