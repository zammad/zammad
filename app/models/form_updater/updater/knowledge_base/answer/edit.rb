# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Form updater for editing a knowledge base answer: the values its tab opens with, and the auto-save
#   that keeps what is typed into them.
#
# One tab is one translation. Which locale that is comes from the tab rather than from the answer
#   (`additional_data['locale']`, see the shared concern), and the title and body seeded below are
#   that translation's.
class FormUpdater::Updater::KnowledgeBase::Answer::Edit < FormUpdater::Updater
  include FormUpdater::Updater::KnowledgeBase::Answer::Concerns::HasCategoryField

  # Form field → the answer's own value for it. Not one of them is a column of the answer: title and
  #   body live on the translation of the edited locale, `categoryId` is `category_id`, and
  #   `visibility` is derived from three timestamps.
  #
  # No `tags`: this form has no tags field. An existing answer is tagged from its sidebar, straight
  #   onto the record (`tagAssignmentAdd`/`tagAssignmentRemove`), so nothing about them travels
  #   through the form at all - not through its draft either.
  #
  # Which is exactly what this table is needed for. FormUpdater::Concerns::StoresTaskbarState
  #   compares every submitted value against the object's own to tell a draft from what is merely on
  #   the record — and `object[field]` answers nil for each of these. Without the mapping the first
  #   round trip would store the answer's own values as a draft, Taskbar#state_changed? would report
  #   an untouched tab as changed, and both its dirty marker and the "editing" badge of the live user
  #   list would light up before anybody typed.
  #
  # It seeds #initial_values as well, which keeps the two in step by construction: what the form is
  #   opened with is precisely what must not count as a change.
  OBJECT_VALUES = {
    'title'      => :stored_title,
    'body'       => :stored_body,
    'categoryId' => :stored_category_id,
    'visibility' => :stored_visibility,
  }.freeze

  def authorized?
    return false if !current_user.permissions?(self.class.required_permissions)
    return false if id.blank?

    # Not the base class's default :show? load — that passes for a reader of the category. Editing
    #   needs #update?, the same query the mutation and the taskbar tab list ask for this answer.
    @object = Gql::ZammadSchema.authorized_object_from_id(id, type: object_type, user: current_user, query: :update?)

    true
  end

  # Seeds the form's upload cache with the answer's own files, and hands the field their cached
  #   copies - which is the only shape it can work with: saving replays the cache onto the answer
  #   (CanCloneAttachments#attach_upload_cache deletes every non-inline attachment first and
  #   re-creates them from the cache, so an empty cache *is* a delete-all), and removing one goes
  #   through the cache as well (`formUploadCacheRemove`).
  #
  # In the updater rather than in a mutation the view calls first, which is how the other forms that
  #   start from a stored record do it — FormUpdater::Concerns::AppliesSplitTicketArticle and
  #   ::AppliesTicketSharedDraft both clone into the cache from here — and it saves a round trip the
  #   form would otherwise have to wait for before it may render.
  #
  # Only for a tab that has stored nothing yet, i.e. the first round trip after it was opened.
  #   Afterwards the cache is what the field reflects, not the answer: seeding again would bring back
  #   a file the editor removed from the draft but has not saved. A reopened tab needs none of this,
  #   because its stored state carries the `form_id` and FormUpdater::AppliesTaskbarState replays the
  #   cache through that (`attachments` is in its SKIP_FIELDS for exactly this reason).
  def resolve
    seed_upload_cache if seed_upload_cache?

    super
  end

  def initial_values
    OBJECT_VALUES.transform_values { |reader| send(reader) }
  end

  private

  def seed_upload_cache?
    meta[:initial] && meta[:form_id].present? && current_taskbar.present? && current_taskbar.state.blank?
  end

  def seed_upload_cache
    UserInfo.with_user_id(current_user.id) do
      object.clone_attachments('UploadCache', meta[:form_id])
    end

    # Through the `form_id` field, so the value is built by FormUpdater::ApplyValue::FormId - the
    #   very same mapping a reopened tab goes through, which keeps the ids the field is handed
    #   identical either way.
    #
    # `as_initial`, because these are the answer's own files: they are what the form opens with, so
    #   they have to be its baseline rather than a change. Without it the file field is dirty from
    #   the moment the tab opens (see the comment in ApplyValue::FormId).
    apply_value.perform(field: 'form_id', config: { 'value' => meta[:form_id], 'as_initial' => true })
  end

  def apply_value
    @apply_value ||= FormUpdater::ApplyValue.new(context:, data:, result:)
  end

  # The answer's own knowledge base, which is not necessarily the active one — the same as
  #   FormUpdater::Updater::KnowledgeBase::Category::Edit does for its category.
  def knowledge_base
    @knowledge_base ||= object.category.knowledge_base
  end

  def object_field?(field)
    OBJECT_VALUES.key?(field)
  end

  def object_field_value(field)
    send(OBJECT_VALUES.fetch(field))
  end

  # The translation the tab edits, or nil while the locale has none yet.
  def translation
    return @translation if defined?(@translation)

    @translation = object.translation_to(kb_locale)
  end

  # Empty rather than absent for a locale the answer has no translation in yet: adding one is a
  #   normal edit (Service::KnowledgeBase::Answer::Update builds it on save), and the form has to
  #   open on empty fields rather than on another locale's text.
  def stored_title
    translation&.title.to_s
  end

  # `body_with_urls`, not the raw body: the stored one carries its inline images as `src="cid:…"`,
  #   which an editor cannot display - the answer would open without its images. The same handover
  #   a ticket shared draft does (Ticket::SharedDraftStart#content_with_body_urls), and what the
  #   answer query's `bodyForEditing` already exposes for the same reason. On the way back
  #   HasRichText turns the URLs into `cid:` again (HtmlSanitizer::CidToSrc, from the `cid`
  #   attribute the editor preserves), so nothing about what is stored changes.
  #
  # It is also what keeps this in step with the taskbar state comparison above: the value seeded
  #   here is the one the form echoes back, so an untouched tab still stores no draft.
  def stored_body
    translation&.content&.body_with_urls.to_s
  end

  def stored_category_id
    object.category_id
  end

  # The state the answer is in *now*, which is what the form deals with: a transition scheduled for
  #   later is shown and managed by a sidebar widget of its own, and an ordinary save leaves it
  #   alone (Service::KnowledgeBase::Answer::Base#scheduled_publication?). So this is simply the
  #   answer's own derived state - CanBePublished takes the highest-ranking timestamp that has
  #   already passed.
  def stored_visibility
    object.visibility.to_s
  end
end
