# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ApplicationPolicy

  # Instances of this class represent Pundit results that mean
  #   "authorization is granted" (= truthy value), but the record's fields
  #   should be restricted.
  class FieldScope

    attr_reader :allow, :deny

    def initialize(allow: nil, deny: nil)
      @allow = allow.to_set(&:to_sym) if allow
      @deny = deny.to_set(&:to_sym) if deny
    end

    def field_authorized?(field)
      if @deny
        return false if @deny.include?(field.to_sym)
        return true if !@allow
      end
      @allow.include?(field.to_sym)
    end
  end
end
