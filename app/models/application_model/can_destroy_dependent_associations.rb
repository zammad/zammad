# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ApplicationModel::CanDestroyDependentAssociations
  extend ActiveSupport::Concern

=begin

This function will search downwards through the has many associations and destroy associations with dependent: :destroy in batches.

  Organization.first.destroy_dependent_associations

returns:

  true

=end

  def destroy_dependent_associations
    self.class.reflect_on_all_associations(:has_many).each do |assoc|
      valid = (assoc.options[:dependent] == :destroy && assoc.options[:through].blank?) || deep_destroy_associations_include.include?(assoc.name)
      next if !valid

      public_send(assoc.name).find_each(batch_size: 100) do |object|
        object.destroy_dependent_associations
        object.destroy
      end
    end
    true
  end

  # This config will allow to include specific associations.
  # e.g. Organizations can be destroy in different modes (unset/destroy all), so we need to flag some
  # associations of it that the function can work properly for organizations as well.
  def deep_destroy_associations_include
    @deep_destroy_associations_include ||= self.class.instance_variable_get(:@deep_destroy_associations_include) || []
  end

  class_methods do
    def deep_destroy_associations_include(*attributes)
      @deep_destroy_associations_include ||= []
      @deep_destroy_associations_include |= attributes
    end
  end
end
