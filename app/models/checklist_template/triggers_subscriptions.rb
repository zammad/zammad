# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module ChecklistTemplate::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_checklist_template_subscriptions
  end

  private

  def trigger_checklist_template_subscriptions
    Gql::Subscriptions::Checklist::TemplateUpdates.trigger(nil, arguments: { only_active: true })
    Gql::Subscriptions::Checklist::TemplateUpdates.trigger(nil, arguments: { only_active: false })
  end
end
