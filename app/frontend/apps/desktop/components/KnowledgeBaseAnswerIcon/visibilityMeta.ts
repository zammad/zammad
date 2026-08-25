// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'

// One icon per publication state, each with its own color and label. Keeping icon, color and
//   label together here means the knowledge base answer list, the AI suggestions in the ticket
//   sidebar and the answer header badge stay in sync, and `satisfies` makes the compiler flag a
//   state that is missing an entry.
// Should be kept in sync with `knowledgeBaseVisibilityMeta` in useKnowledgeBaseVisibility.ts,
//   which is used to compute the category icon and color for a given state.
export const visibilityMeta = {
  [EnumKnowledgeBaseVisibility.Draft]: {
    icon: 'kb-draft',
    label: __('Draft'),
    class: 'text-stone-200! dark:text-neutral-500!',
  },
  [EnumKnowledgeBaseVisibility.Internal]: {
    icon: 'kb-internal',
    label: __('Internal'),
    class: 'text-blue-800!',
  },
  [EnumKnowledgeBaseVisibility.Published]: {
    icon: 'kb-published',
    label: __('Published'),
    class: 'text-green-400!',
  },
  [EnumKnowledgeBaseVisibility.Archived]: {
    icon: 'kb-archived',
    label: __('Archived'),
    class: 'text-neutral-400! dark:text-neutral-600!',
  },
} as const satisfies Record<
  EnumKnowledgeBaseVisibility,
  { icon: string; label: string; class: string }
>
