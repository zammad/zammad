# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Administering the knowledge base itself: creating it, editing every one of its attributes,
#   switching it on and off, its server snippets and its public menus. All of it is
#   `admin.knowledge_base`, which is what the legacy admin interface behind these endpoints is
#   registered with (`permission: ['admin.knowledge_base']` in
#   app/assets/javascripts/app/controllers/_manage/knowledge_base.coffee).
#
# The default covers the whole controller rather than being spelled out per action because that is
#   the actual rule here - there is no action on it that a non-administrator may reach. That makes
#   it safe for `resources :manage` to route `index`, `new` and `edit`, which
#   KnowledgeBase::ManageController does not implement.
#
# Note KnowledgeBase::ManageController#params_for_permission is `params.permit!` and its #destroy
#   is `full_destroy!`, so #update? and #destroy? in particular must not resolve to anything
#   weaker: an unfiltered write of every attribute, and the removal of the knowledge base with all
#   of its content.
class Controllers::KnowledgeBase::ManageControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.knowledge_base')
end
