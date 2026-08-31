// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isEqual } from 'lodash-es'

import type { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'

import type { KnowledgeBaseAnswerHeader } from '../../types.ts'

// What the tab opened with, for the two things a foreign save can change under it. Snapshotted
//   rather than read live: the answer is live-updated by its subscription, so comparing it against
//   itself would never report a change.
export interface OpenedWith {
  editedAt?: string | null
  attachments: { name: string; size: number }[]
  categoryId: string
  visibility: EnumKnowledgeBaseVisibility
}

export interface ConcurrentChange {
  // Absent for two reasons, both ending in the message that names nobody rather than in no message
  //   at all: the editor may not be looked at (UserPolicy#nested_show? asks for ticket or admin
  //   permission, so a knowledge base editor without either gets a null `editedBy`), or the change
  //   is one nobody is recorded for - see the attribution note in `concurrentChange`.
  editorName?: string
}

// One message for the banner and for the confirmation on submit: it says the same thing in both
//   places, and saying it twice in two wordings only invites them to drift. The banner adds a link
//   to the stored answer after it, which is why the link is not part of the sentence.
export const CONCURRENT_CHANGE_MESSAGE = __(
  '%s has updated this answer. Submitting will replace their changes.',
)

export const CONCURRENT_CHANGE_MESSAGE_WITHOUT_EDITOR = __(
  'This answer has been updated. Submitting will replace those changes.',
)

export const attachmentIdentities = (
  attachments: KnowledgeBaseAnswerHeader['attachments'],
): OpenedWith['attachments'] =>
  attachments.map((file) => ({ name: file.name, size: file.size ?? 0 }))

// `editedAt` covers the title and the body: it moves for exactly those two and for nothing else -
//   not for a tag, not for a link, and not for a sibling locale. Everything else a save of this
//   form writes has to be compared on its own value:
//
//   - the attachment set, which no timestamp reflects at all - and which is the change that would
//     silently delete somebody's file, so the one that must not go unmentioned;
//   - the category and the publication state, which move `updated_at` only. They are the changes an
//     editor of *another locale's* tab makes without touching a word of this translation, and this
//     form resubmits both on every save - so without comparing them a save reverts them silently.
// Everything a foreign save can change under the tab, plus who did it. `id` is not part of the
//   comparison - it is what the banner's link to the stored answer needs.
export type ComparableAnswer = Pick<
  KnowledgeBaseAnswerHeader,
  'id' | 'editedAt' | 'editedBy' | 'attachments' | 'category' | 'visibility'
>

export const concurrentChange = (
  answer: ComparableAnswer | undefined,
  openedWith: OpenedWith | undefined,
): ConcurrentChange | undefined => {
  if (!answer || !openedWith) return undefined

  // The two halves are kept apart because only the first one has an editor recorded for it.
  const translationChanged = answer.editedAt !== openedWith.editedAt

  const answerChanged =
    answer.category.id !== openedWith.categoryId ||
    answer.visibility !== openedWith.visibility ||
    !isEqual(attachmentIdentities(answer.attachments), openedWith.attachments)

  if (!translationChanged && !answerChanged) return undefined

  // `editedBy` is whoever last edited *this translation's* title or body, and it moves together
  //   with `editedAt` - so it names the author of this change only when that timestamp moved too.
  //   A change to the category, the state or the attachments leaves both untouched: naming that
  //   editor there would credit somebody who may have had nothing to do with it, and who may even
  //   be the editor reading the warning. Then the message that names nobody is the honest one.
  return {
    editorName: translationChanged ? (answer.editedBy?.fullname ?? undefined) : undefined,
  }
}
