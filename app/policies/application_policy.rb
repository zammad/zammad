# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ApplicationPolicy
  include PunditPolicy

  attr_reader :record

  def initialize_context(record)
    @record = record
  end
end
