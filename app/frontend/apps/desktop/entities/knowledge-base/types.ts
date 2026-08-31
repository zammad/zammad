// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EnumKnowledgeBaseVisibility, Scalars } from '#shared/graphql/schema-types.ts'

// Derived from the schema scalar, so the icon sprite file names cannot drift
//   from what the backend allows.
export type KnowledgeBaseIconSet = Scalars['KnowledgeBaseIconSet']['output']

export interface DeletableKnowledgeBaseCategory {
  id: string
  title?: Maybe<string>
  isDeletable?: Maybe<boolean>
}

// What the answer create form submits. Its visibility takes effect as soon as the answer is saved:
//   this form carries no date to schedule one for later with, that being an edit
//   (see KnowledgeBaseAnswerEditFormData).
export interface KnowledgeBaseAnswerCreateFormData {
  categoryId: string | number
  title: string
  body?: string
  tags?: string[]
  visibility?: EnumKnowledgeBaseVisibility
  // The locale the draft is written in, from the route rather than the form.
  locale: string
}

// What the answer edit form submits. No `tags`: editing an answer manages tags from the sidebar
//   instead of a form field, next to the live Related Tickets list.
//
// No date next to the visibility either: this form sets the state the answer is in *now*. A
//   transition scheduled for later is shown and managed by a sidebar widget of its own
//   of its own, and an ordinary save leaves it alone
//   (Service::KnowledgeBase::Answer::Base#scheduled_publication?).
export interface KnowledgeBaseAnswerEditFormData {
  categoryId: string | number
  title: string
  body?: string
  visibility?: EnumKnowledgeBaseVisibility
  // The locale the translation is written in, from the route rather than the form.
  locale: string
}
