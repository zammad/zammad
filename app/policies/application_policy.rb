class ApplicationPolicy
  include PunditPolicy

  attr_reader :record

  def initialize_context(record)
    @record = record
  end

  class Scope
    include PunditPolicy

    attr_reader :scope

    def initialize_context(scope)
      @scope = scope
    end
  end
end
