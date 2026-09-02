// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumKnowledgeBaseSchedulableVisibility } from '#shared/graphql/types.ts'

import { visibilityMeta } from '#desktop/components/KnowledgeBaseAnswerIcon/visibilityMeta.ts'

// The two enums name the same states, and their generated values are identical: the schedulable one
//   is the answer's own visibility without `draft`, which stores no date and can therefore not be
//   scheduled. TypeScript keeps them apart all the same, so the lookup into the shared
//   icon/colour/label map is bridged here rather than at every use.
export const metaFor = (visibility: EnumKnowledgeBaseSchedulableVisibility) =>
  visibilityMeta[visibility]

export const colorFor = (visibility: EnumKnowledgeBaseSchedulableVisibility) =>
  metaFor(visibility).class
