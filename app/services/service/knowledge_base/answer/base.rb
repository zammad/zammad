# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared write plumbing of the knowledge base answer write services: what an answer is made of, and
#   where each part of it lives.
class Service::KnowledgeBase::Answer::Base < Service::KnowledgeBase::Base
  # Editor access to an answer is gated by the mutations' `answer_id` argument, but a user is needed
  #   all the same: where an answer may be *filed* is KnowledgeBase::AnswerPolicy#create?, which no
  #   argument gate answers; whether a tag that does not exist yet may be created is decided per
  #   user; and every publication date credits whoever changed it
  #   (CanBePublished#update_user_references).
  requires_current_user!

  private

  # Title and body live on the translation of one locale and on its content record, not on the
  #   answer. An absent value leaves the stored one alone, so an update can touch the body without
  #   resubmitting the title.
  #
  # Assigns in memory only. The caller saves the answer once, which autosaves the translation and
  #   its content (both associations are declared with `accepts_nested_attributes_for`) — so
  #   KnowledgeBase::HasUniqueTitle validates the title against the siblings in the *submitted*
  #   category, and a rejected move leaves no saved title behind. It also puts every translation
  #   error on the answer's `translations.…` path (HasTranslations#validate_translations), which is
  #   the path the form maps back onto its own fields.
  def assign_translation(answer, kb_locale, title:, body:)
    return if title.nil? && body.nil?

    translation = translation_for(answer, kb_locale)

    ensure_title_present!(translation, title)

    translation.title = title if !title.nil?

    # Not folded into the line above: a translation without content does not validate, so a new one
    #   has to get one even when only a title was submitted.
    content = content_for(translation)
    content.body = body if !body.nil?
  end

  # The translation of the given locale, or a new one. Building it is the normal case for an update
  #   too: a locale an answer has no translation in yet is exactly where it gets its next one, which
  #   is what the client sees as `translationMissing`.
  #
  # `detect` over the loaded association rather than a query, so a translation built earlier in the
  #   same call is found again.
  def translation_for(answer, kb_locale)
    answer.translations.detect { |translation| translation.kb_locale_id == kb_locale.id } ||
      answer.translations.build(kb_locale: kb_locale)
  end

  # A translation the answer does not have yet cannot be built without a title: the presence
  #   validation on it would be reported on the answer's `translations.title` path, and generating
  #   that message reads the attribute off the *answer*, which has no such method — so the result is
  #   a NoMethodError rather than a validation error the form could show.
  #
  # The same guard Service::KnowledgeBase::Category::Create has for its own titles, and the same
  #   message. Only for a translation that is being built: an existing one keeps the title it has,
  #   which is what makes saving a body on its own possible.
  def ensure_title_present!(translation, title)
    return if translation.persisted?
    return if title.present?

    raise Exceptions::UnprocessableContent, __('A title is required.')
  end

  # A translation does not validate without a content record (its `belongs_to :content` is
  #   required), so a new one always gets one — empty when only a title was submitted.
  #
  # Deliberately no `form_id` on the content: HasRichText#has_rich_text_pickup_attachments would
  #   then copy every non-inline file of the form's upload cache onto the content as well,
  #   duplicating what the answer's own attachments already hold. The body's inline images do not
  #   need it — they travel inside the body and are pulled out of it on save.
  def content_for(translation)
    translation.content || translation.build_content(body: '')
  end

  # The submitted state is the *target* state, and it is not stored: CanBePublished derives it from
  #   the timestamps. So reaching a state means stamping its own timestamp and clearing the ones that
  #   would win over it, and reaching `draft` means clearing all of them.
  #
  # It always takes effect at once — the state an answer is in *now* is the only one submitted, and
  #   a transition scheduled for later is managed apart from the answer's data. The old interface
  #   does write such schedules (CanBePublished#schedule_touch is what makes the answer surface once
  #   one is reached), so the columns are read with that in mind — see #scheduled_publication?.
  #
  # Not the AASM events of the state machine: no event leads back to `draft`, and `set_timestamp`
  #   would rewrite a date that is already in effect.
  def assign_visibility(answer, state)
    return if state.blank?

    target = visibility_rank(state)

    CanBePublished::SCHEDULABLE_VISIBILITIES.each_value.with_index do |column, rank|
      answer[column] = publication_timestamp(answer[column], rank <=> target)
    end
  end

  # @param current [ActiveSupport::TimeWithZone, nil] what the column holds
  # @param position [Integer] where this state ranks relative to the target one
  def publication_timestamp(current, position)
    case position
    when 1  # would win over the state that was asked for
      scheduled_publication?(current) ? current : nil
    when 0
      publication_in_effect?(current) ? current : now
    else    # how the answer got here - kept, unless it has not taken effect yet
      publication_in_effect?(current) ? current : nil
    end
  end

  # What "now" is stamped as, down to the minute — the same as CanBePublished::StateMachine's own
  #   `set_timestamp`. A state only takes effect once its timestamp has *passed*
  #   (CanBePublished::StateMachine#calculated_state_valid? compares with `<`), so stamping the exact
  #   current instant would leave the answer a draft — which is what the mutation would render back
  #   right after publishing it.
  def now
    @now ||= Time.zone.now.change(sec: 0)
  end

  # -1 for `draft`, which has no timestamp of its own: every state ranks above it, so all of them
  #   are cleared.
  def visibility_rank(state)
    return -1 if state == :draft

    CanBePublished::SCHEDULABLE_VISIBILITIES.keys.index(state) ||
      raise(ArgumentError, "Unknown publication state '#{state}'.")
  end

  # Whether the answer's state is actually derived from this timestamp already.
  #
  # Such a date is kept rather than restamped: the form sends the stored state back on every round
  #   trip, and rewriting `published_at` would creep the publication date — and with it
  #   `published_by`, which CanBePublished#update_user_references credits on every changed timestamp
  #   — forward on every edit of a title.
  def publication_in_effect?(current)
    current.present? && current <= now
  end

  # A timestamp that has not been reached yet is a *scheduled* transition, and setting the answer's
  #   current state must not delete it: it ranks above whatever is in effect now by definition (or it
  #   could not take effect at all), so it would otherwise be cleared by the branch above on every
  #   ordinary save - an editor fixing a typo would cancel a publication the old interface scheduled,
  #   without being told.
  def scheduled_publication?(current)
    current.present? && current > now
  end

  # An empty list is what "no tags" looks like, while an absent one leaves the stored tags alone.
  #
  # Not Tag.tag_update's own list: it creates whatever it is given (`lookup_by_name_and_create`),
  #   while creating a tag that does not exist yet is what the `tag_new` setting governs — so an
  #   unknown tag is skipped rather than refused, the same as in Service::Ticket::Create.
  def assign_tags(answer, tags)
    return if tags.nil?

    allowed = tags
      .map(&:strip)
      .select { |tag| ::Tag.tag_allowed?(name: tag, user_id: current_user.id) }

    answer.tag_update(allowed, current_user.id)
  end

  # The model's own way in from a form's upload cache. It skips the cache's inline images — those
  #   belong to the body, and HasRichText pulls them out of it into attachments of the translation
  #   content.
  #
  # Not `answer.attachments=`: that buffer credits the store item to the record's `created_by_id`,
  #   and `knowledge_base_answers` has no such column.
  #
  # **It clears the answer's existing files first**, so the cache has to hold everything the answer
  #   is supposed to end up with — for an update that means the files it already has, cloned into the
  #   cache when the tab was opened. A form that submits its id without that seeding empties the
  #   answer's attachments on the first save.
  def attach_files(answer, form_id)
    return if form_id.blank?

    answer.attach_upload_cache(form_id)
  end
end
