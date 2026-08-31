// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'

// The publication states as the forms offer them, label and description together.
//
// The labels and the three published-state notes are the ones the legacy form shows
//   (App.KnowledgeBaseContentCanBePublishedForm), so the existing translations apply; the archived
//   note is copy from the design, which the legacy form has none for.
//
// Shared, so the answer form and the schedule flyout cannot drift apart on what a state is called -
//   the flyout offers the same set minus `draft`, which stores no date and can therefore not be
//   scheduled (see answerSchedulableVisibilityOptions below).
export const answerVisibilityOptions = [
  {
    value: EnumKnowledgeBaseVisibility.Draft,
    label: __('Draft'),
    description: __('Only visible to editors'),
  },
  {
    value: EnumKnowledgeBaseVisibility.Internal,
    label: __('Internal'),
    description: __('Visible to readers & editors'),
  },
  {
    value: EnumKnowledgeBaseVisibility.Published,
    label: __('Public'),
    description: __('Visible to everyone'),
  },
  {
    value: EnumKnowledgeBaseVisibility.Archived,
    label: __('Archived'),
    description: __('Archive this answer'),
  },
] as const

// What a visibility change can be scheduled to reach: everything but `draft`, which is what no date
//   at all means - mirroring EnumKnowledgeBaseSchedulableVisibility, which the mutation takes.
export const answerSchedulableVisibilityOptions = answerVisibilityOptions.filter(
  (option) => option.value !== EnumKnowledgeBaseVisibility.Draft,
)
