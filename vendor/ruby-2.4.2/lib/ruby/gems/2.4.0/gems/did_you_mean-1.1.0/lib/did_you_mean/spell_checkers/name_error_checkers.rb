require 'did_you_mean/spell_checkers/name_error_checkers/class_name_checker'
require 'did_you_mean/spell_checkers/name_error_checkers/variable_name_checker'

module DidYouMean
  module NameErrorCheckers
    def self.included(*)
      raise "Do not include this module since it overrides Class.new method."
    end

    def self.new(exception)
      case exception.original_message
      when /uninitialized constant/
        ClassNameChecker
      when /undefined local variable or method/,
           /undefined method/,
           /uninitialized class variable/,
           /no member '.*' in struct/
        VariableNameChecker
      else
        NullChecker
      end.new(exception)
    end
  end
end
