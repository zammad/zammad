# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::AppliesTicketTemplate
  extend ActiveSupport::Concern

  def resolve
    if agent? && selected_template.present?
      apply_template
    end

    super
  end

  private

  def apply_template
    apply_value = FormUpdater::ApplyValue.new(context:, data:, dirty_fields: meta[:dirty_fields], result:)
    selected_template.options.each_pair do |fieldpath, config|
      apply_value.perform(field: fieldpath.split('.').last, config:)
    end
  end

  def selected_template
    tid = meta.dig(:additional_data, 'templateId')
    Gql::ZammadSchema.authorized_object_from_id(tid, type: Template, user: context[:current_user]) if tid.present?
  end

  def agent?
    current_user.permissions?('ticket.agent')
  end
end
