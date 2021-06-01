# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasGroupRelationDefinition
  extend ActiveSupport::Concern

  included do

    self.table_name   = "groups_#{group_relation_model_identifier}s"
    self.primary_keys = ref_key, :group_id, :access

    belongs_to group_relation_model_identifier, optional: true
    belongs_to :group, optional: true

    validates :access, presence: true
    validate :validate_access

    after_save :touch_related
    after_destroy :touch_related
  end

  private

  def group_relation_instance
    @group_relation_instance ||= send(group_relation_model_identifier)
  end

  def group_relation_model_identifier
    @group_relation_model_identifier ||= self.class.group_relation_model_identifier
  end

  def touch_related
    # rubocop:disable Rails/SkipsModelValidations
    group.touch if group&.persisted?
    group_relation_instance.touch if group_relation_instance&.persisted?
    # rubocop:enable Rails/SkipsModelValidations
  end

  def validate_access
    query = self.class.where(
      group_relation_model_identifier => group_relation_instance,
      group: group
    )

    query = if access == 'full'
              query.where.not(access: 'full')
            else
              query.where(access: 'full')
            end

    return if !query.exists?

    errors.add(:access, "#{group_relation_model_identifier.to_s.capitalize} can have full or granular access to group")
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

    def group_relation_model_identifier
      @group_relation_model_identifier ||= model_name.singular.split('_').first.to_sym
    end

    def ref_key
      @ref_key ||= :"#{group_relation_model_identifier}_id"
    end
  end
end
