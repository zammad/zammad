// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'

// One icon per publication state, each with its own color and label. Keeping icon, color and
//   label together here means the knowledge base answer list, the AI suggestions in the ticket
//   sidebar and the answer header badge stay in sync, and `satisfies` makes the compiler flag a
//   state that is missing an entry.
// Should be kept in sync with `knowledgeBaseVisibilityMeta` in useKnowledgeBaseVisibility.ts,
//   which is used to compute the category icon and color for a given state.
//
// `timestampLabel` is how a reached date of that state is named where it is shown as a value of its
//   own - "Internally published" rather than the badge's "Internal". Required of every state but
//   `draft`, which is the absence of all three dates and therefore has no date to label: hence the
//   intersection below rather than one optional field, which would have let a missing label through
//   for the three states that do need one.
export const visibilityMeta = {
  [EnumKnowledgeBaseVisibility.Draft]: {
    icon: 'kb-draft',
    label: __('Draft'),
    class: 'text-stone-200! dark:text-neutral-500!',
  },
  [EnumKnowledgeBaseVisibility.Internal]: {
    icon: 'kb-internal',
    label: __('Internal'),
    timestampLabel: __('Internally published'),
    class: 'text-blue-800!',
  },
  [EnumKnowledgeBaseVisibility.Published]: {
    icon: 'kb-published',
    label: __('Published'),
    timestampLabel: __('Published'),
    class: 'text-green-400!',
  },
  [EnumKnowledgeBaseVisibility.Archived]: {
    icon: 'kb-archived',
    label: __('Archived'),
    timestampLabel: __('Archived'),
    class: 'text-gray-100! dark:text-neutral-400!',
  },
} as const satisfies Record<
  EnumKnowledgeBaseVisibility,
  { icon: string; label: string; class: string }
> &
  Record<
    Exclude<EnumKnowledgeBaseVisibility, EnumKnowledgeBaseVisibility.Draft>,
    { timestampLabel: string }
  >
