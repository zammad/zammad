// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'

import KnowledgeBaseAnswerIcon from '../KnowledgeBaseAnswerIcon.vue'

const renderIcon = (visibility: EnumKnowledgeBaseVisibility) =>
  renderComponent(KnowledgeBaseAnswerIcon, { props: { visibility } })

describe('KnowledgeBaseAnswerIcon', () => {
  it.each([
    [EnumKnowledgeBaseVisibility.Draft, 'kb-draft', 'Draft'],
    [EnumKnowledgeBaseVisibility.Internal, 'kb-internal', 'Internal'],
    [EnumKnowledgeBaseVisibility.Published, 'kb-published', 'Published'],
    [EnumKnowledgeBaseVisibility.Archived, 'kb-archived', 'Archived'],
  ])('renders %s answers with their own icon', (visibility, icon, label) => {
    const view = renderIcon(visibility)

    expect(view.getByIconName(icon)).toBeInTheDocument()
    expect(view.getByLabelText(label)).toBeInTheDocument()
  })
})
