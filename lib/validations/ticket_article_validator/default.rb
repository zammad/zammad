# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Validations::TicketArticleValidator
  class Default < Backend
    def validate_body
      return if @record.body.present?

      @record.errors.add :base, __("Need at least an 'article body' field.")
    end
  end
end
