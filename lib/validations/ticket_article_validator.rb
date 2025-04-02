# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Validations::TicketArticleValidator < ActiveModel::Validator
  include ::Mixin::HasBackends

  def validate(record)
    return if ApplicationHandleInfo.postmaster?

    backend(record)
      .new(record)
      .validate
  end

  private

  def backend(record)
    backend_by_type(record) || backend_default
  end

  def backend_by_type(record)
    type = Ticket::Article::Type.lookup(id: record.type_id)

    backends.find do |elem|
      next if !elem.const_defined?(:MATCHING_TYPES)

      elem::MATCHING_TYPES.include? type.name
    end

  end

  def backend_default
    self.class::Default
  end
end
