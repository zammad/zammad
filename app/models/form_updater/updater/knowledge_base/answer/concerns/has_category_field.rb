# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The shared body of the answer create and edit form updaters: the category selection resolved
#   through FormUpdater::Relation::KnowledgeBaseEditorCategory, plus the auto-save both tabs live
#   off — FormUpdater::Concerns::StoresTaskbarState writes every resolved field into
#   `taskbar.state` on each round trip and FormUpdater::Concerns::AppliesTaskbarState plays it
#   back when the tab is reopened.
#
# That auto-save is the actual reason an answer form talks to an updater at all: there are no
#   object attributes to resolve, because KnowledgeBase::Answer is not an object manager object
#   and its form is hand-declared on the frontend (hence no ChecksCoreWorkflow either).
#
# Attachments are not part of the state — AppliesTaskbarState::SKIP_FIELDS excludes them, and the
#   stored `form_id` is what brings them back: FormUpdater::ApplyValue::FormId reads the upload
#   cache the draft files live in (Taskbar::HasAttachments) and fills the `attachments` field from
#   it. Nothing to route through here.
#
# Includers provide #knowledge_base, and #initial_values for what the form starts out with.
module FormUpdater::Updater::KnowledgeBase::Answer::Concerns::HasCategoryField
  extend ActiveSupport::Concern

  include FormUpdater::Concerns::AppliesTaskbarState
  include FormUpdater::Concerns::ProvidesInitialValues
  include FormUpdater::Concerns::StoresTaskbarState

  class_methods do
    def required_permissions
      ['knowledge_base.editor']
    end
  end

  def object_type
    ::KnowledgeBase::Answer
  end

  def resolve
    # Which category is picked is only ever an *initial* value (see #initial_values) — resending
    #   it later would overwrite whatever the user has chosen since.
    #
    # Unlike the category form's parent field this one is required unconditionally: an answer
    #   always belongs to a category, so there is no "top level" an empty field could mean. It is
    #   sent all the same, so the field's contract travels with its options; that it must not be
    #   clearable is the frontend schema's business, the updater has no way to express it.
    result['categoryId'] = { options: category_relation.options, required: true }

    resolved = super

    drop_unoffered_category

    resolved
  end

  private

  # A draft carries its category in the taskbar state, which FormUpdater::Concerns::
  #   AppliesTaskbarState plays straight back into the field - unfiltered, unlike the seed a create
  #   resolves through #seeded_category. So a draft whose category the editor has meanwhile lost
  #   access to (or that was deleted) comes back with a value its own option list does not contain:
  #   a treeselect showing nothing, and a create the service refuses on submit.
  #
  # Dropping it leaves the field empty instead, and since it is required the form makes the editor
  #   pick a category they may actually write to before it submits.
  #
  # After `super`, because that is when the state has been applied. What is already stored stays
  #   stored until the field is set again - only a round trip that stores could rewrite it, and by
  #   then the editor has had to pick.
  def drop_unoffered_category
    category_id = result.dig('categoryId', :value)
    return if category_id.blank?
    return if category_relation.selectable_categories.any? { |category| category.id == category_id.to_i }

    result['categoryId'].delete(:value)
  end

  # The locale the *draft* is written in, which the client sends along with the taskbar it stores
  #   into — not the user's preferred one. A tab is one answer translation, so its category titles
  #   have to read in the same language as its breadcrumb and its answer; an editor whose profile
  #   is English writing a German answer would otherwise pick from English category names.
  #
  # Falls back to the preferred locale for a client that names none, or names one this knowledge
  #   base does not have: unlike a mutation, which must refuse to write into a locale it was not
  #   asked for, this only decides what the options are labelled with.
  def kb_locale
    @kb_locale ||= submitted_kb_locale || ::KnowledgeBase::Locale.preferred(current_user, knowledge_base)
  end

  def submitted_kb_locale
    locale_code = meta.dig(:additional_data, 'locale')
    return if locale_code.blank?

    knowledge_base.kb_locales.joins(:system_locale).find_by(locales: { locale: locale_code })
  end

  # Nothing to exclude: unlike a category, an answer is never a parent of anything, so every
  #   category the user is an editor of is a valid target. #top_level_selectable? is not asked
  #   either — an answer always belongs to a category, there is no top level for it.
  def category_relation
    @category_relation ||= FormUpdater::Relation::KnowledgeBaseEditorCategory.new(
      context:           context,
      current_user:      current_user,
      data:              data,
      knowledge_base:    knowledge_base,
      excluded_category: nil,
      kb_locale:         kb_locale,
    )
  end
end
