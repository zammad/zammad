# frozen-string-literal: true
require 'did_you_mean/formatter'

module DidYouMean
  module VerboseFormatter
    prepend_features DidYouMean::Formatter

    def to_s
      return "" if @corrections.empty?

      output = "\n\n    Did you mean? ".dup
      output << @corrections.join("\n                  ")
      output << "\n "
    end
  end
end
