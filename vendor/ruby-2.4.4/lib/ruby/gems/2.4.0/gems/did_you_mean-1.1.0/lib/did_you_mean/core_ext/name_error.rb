module DidYouMean
  module Correctable
    prepend_features NameError

    def original_message
      method(:to_s).super_method.call
    end

    def to_s
      msg = super.dup
      bt  = caller(1, 6)

      msg << Formatter.new(corrections).to_s if IGNORED_CALLERS.all? {|ignored| bt.grep(ignored).empty? }
      msg
    rescue
      super
    end

    def corrections
      spell_checker.corrections
    end

    def spell_checker
      @spell_checker ||= SPELL_CHECKERS[self.class.to_s].new(self)
    end
  end
end
