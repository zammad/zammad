// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, toValue, watch } from 'vue'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { knowledgeBaseAnswerRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import {
  attachmentIdentities,
  concurrentChange,
  CONCURRENT_CHANGE_MESSAGE,
  CONCURRENT_CHANGE_MESSAGE_BY_CURRENT_USER,
  CONCURRENT_CHANGE_MESSAGE_WITHOUT_EDITOR,
  type ComparableAnswer,
  type OpenedWith,
} from './concurrentChange.ts'

import type { MaybeRefOrGetter } from 'vue'

// Somebody else saving this translation while the tab is open: what the banner says, what the
//   confirmation on submit asks, and what the mutation has to be told about it. One place, because
//   all three have to agree about whether there is a conflict at all - and because the answer they
//   compare against is a snapshot that only this may move.
export const useKnowledgeBaseAnswerConcurrentChange = (options: {
  answer: MaybeRefOrGetter<ComparableAnswer | undefined>
  // Whether `answer` is what the server last said, rather than a cache hit still awaiting its
  //   round trip (useKnowledgeBaseAnswer's `answerConfirmed`). The baseline below must not be
  //   taken from anything else - see the comment on the watcher.
  answerConfirmed: MaybeRefOrGetter<boolean>
  // The locale of the tab, for the link to the stored answer: one tab is one translation.
  localeCode: MaybeRefOrGetter<string>
}) => {
  const { waitForConfirmation } = useConfirmation()
  const session = useSessionStore()

  // The answer as this tab opened it. Captured once and moved only by this editor's own save (see
  //   `snapshotAnswer`): the answer is live-updated by its subscription, so comparing it against
  //   itself at save time would show their change and compare equal - precisely the case that must
  //   not pass.
  //
  // `attachments` is the answer's stored, non-inline set; the inline images of the body are not in
  //   it.
  const openedWith = ref<OpenedWith>()

  const snapshotAnswer = (loaded = toValue(options.answer)) => {
    if (!loaded) return

    openedWith.value = {
      editedAt: loaded.translation?.editedAt,
      attachments: attachmentIdentities(loaded.attachments),
      categoryId: loaded.category.id,
      visibility: loaded.visibility,
    }
  }

  // Only once the server has confirmed the answer, never off a cache hit that is still awaiting
  //   its round trip. The app queries `cache-and-network`, so reopening this tab after somebody
  //   else changed the answer serves the entry this tab left behind first - and a baseline taken
  //   from that would be contradicted by the very next result, reporting a change that happened
  //   before the tab was even opened and demanding a confirmation for it.
  //
  // Both are watched, not just the answer: a network result equal to what the cache held may not
  //   move `answer` at all, and the baseline still has to be taken then.
  watch(
    () => [toValue(options.answer), toValue(options.answerConfirmed)] as const,
    ([loaded, confirmed]) => {
      if (openedWith.value || !confirmed) return

      snapshotAnswer(loaded)
    },
    { immediate: true },
  )

  const foreignChange = computed(() =>
    concurrentChange(toValue(options.answer), openedWith.value, session.user?.id),
  )

  // What the banner announces, which is less than the submit asks about: the editor's own save from
  //   another session has nobody to warn them about, while the confirmation below still asks before
  //   their unsaved work replaces it.
  //
  // Only when nothing outside the translation moved: those changes record no editor, so this cannot
  //   know it was them - and the attachment set among them is the one a save can silently delete.
  const announcedChange = computed(() => {
    const change = foreignChange.value

    if (!change) return undefined
    if (change.byCurrentUser && !change.answerChanged) return undefined

    return change
  })

  const foreignChangeMessage = computed(() => {
    if (foreignChange.value?.byCurrentUser) return CONCURRENT_CHANGE_MESSAGE_BY_CURRENT_USER

    return foreignChange.value?.editorName
      ? CONCURRENT_CHANGE_MESSAGE
      : CONCURRENT_CHANGE_MESSAGE_WITHOUT_EDITOR
  })

  // The answer as it is stored now, for the banner to link to - the reader's own view of it, in the
  //   locale being edited.
  const storedAnswerLink = computed(() => {
    const answer = toValue(options.answer)

    return answer ? knowledgeBaseAnswerRoute(toValue(options.localeCode), answer.id) : undefined
  })

  // The files as the tab opened, which the backend needs to tell a foreign attachment change from
  //   this editor's own (Service::KnowledgeBase::Answer::Update::Validator
  //   ::ConcurrentAttachmentChange).
  const knownAttachments = computed(() => openedWith.value?.attachments)

  // Asked only when there is something to lose: an unconditional dialog on every save trains the
  //   editor to click it away, which costs exactly the attention it is meant to buy. The wording is
  //   the banner's, so being asked says no more than what has been on screen all along.
  //
  // @returns whether the save may go ahead
  const confirmForeignChange = async () => {
    if (!foreignChange.value) return true

    return waitForConfirmation(foreignChangeMessage.value, {
      textPlaceholder:
        !foreignChange.value.byCurrentUser && foreignChange.value.editorName
          ? [foreignChange.value.editorName]
          : undefined,
      headerTitle: __('Submit your changes'),
      buttonLabel: __('Submit'),
      buttonVariant: 'danger',
    })
  }

  return {
    foreignChange,
    announcedChange,
    foreignChangeMessage,
    storedAnswerLink,
    knownAttachments,
    snapshotAnswer,
    confirmForeignChange,
  }
}
