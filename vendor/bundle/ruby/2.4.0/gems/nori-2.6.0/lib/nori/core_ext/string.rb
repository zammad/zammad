class Nori
  module CoreExt
    module String

      # Returns the String in snake_case.
      def snakecase
        str = dup
        str.gsub!(/::/, '/')
        str.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        str.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
        str.tr! ".", "_"
        str.tr! "-", "_"
        str.downcase!
        str
      end unless method_defined?(:snakecase)

    end
  end
end

String.send :include, Nori::CoreExt::String
