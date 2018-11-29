module Doorkeeper
  module Validations
    extend ActiveSupport::Concern

    attr_accessor :error

    def validate
      @error = nil
      self.class.validations.each do |validation|
        break if @error
        @error = validation.last unless send("validate_#{validation.first}")
      end
    end

    def valid?
      validate
      @error.nil?
    end

    module ClassMethods
      def validate(attribute, options = {})
        validations << [attribute, options[:error]]
      end

      def validations
        @validations ||= []
      end
    end
  end
end
