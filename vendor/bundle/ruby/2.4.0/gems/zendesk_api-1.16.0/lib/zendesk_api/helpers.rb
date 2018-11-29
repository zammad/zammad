module ZendeskAPI
  # @private
  module Helpers
    # From https://github.com/rubyworks/facets/blob/master/lib/core/facets/string/modulize.rb
    def self.modulize_string(string)
      # gsub('__','/').  # why was this ever here?
      string.gsub(/__(.?)/) { "::#{$1.upcase}" }.
        gsub(/\/(.?)/) { "::#{$1.upcase}" }.
        gsub(/(?:_+|-+)([a-z])/) { $1.upcase }.
        gsub(/(\A|\s)([a-z])/) { $1 + $2.upcase }
    end

    # From https://github.com/rubyworks/facets/blob/master/lib/core/facets/string/snakecase.rb
    def self.snakecase_string(string)
      # gsub(/::/, '/').
      string.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').
        tr('-', '_').
        gsub(/\s/, '_').
        gsub(/__+/, '_').
        downcase
    end
  end
end
