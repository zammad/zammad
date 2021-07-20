# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ApplicationPolicy
  class Scope
    include PunditPolicy

    attr_reader :scope

    def initialize_context(scope)
      @scope = scope
    end
  end
end
