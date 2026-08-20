# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Deletes an empty knowledge base category.
#
# A category with subcategories or answers is not deleted recursively: both associations are
#   `dependent: :restrict_with_exception`, so `destroy!` raises ActiveRecord::DeleteRestrictionError
#   and the caller turns that into a user error. Emptying it first is a deliberate, explicit step.
class Service::KnowledgeBase::Category::Delete < Service::Base
  requires_current_user!

  attr_reader :category

  # @param category [KnowledgeBase::Category] category to delete
  def initialize(category:)
    @category = category
  end

  def execute
    Pundit.authorize current_user, category, :destroy?

    category.destroy!

    true
  end
end
