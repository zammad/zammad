// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import KnowledgeBaseAnswerHeaderDetails from '../KnowledgeBaseAnswerHeaderDetails.vue'

import type { KnowledgeBaseAnswerHeader } from '../../../types.ts'

const CURRENT_USER_ID = convertToGraphQLId('User', 1)
const OTHER_USER_ID = convertToGraphQLId('User', 2)

const answer = (overrides: Partial<KnowledgeBaseAnswerHeader> = {}): KnowledgeBaseAnswerHeader =>
  ({
    id: convertToGraphQLId('KnowledgeBase::Answer', 1),
    title: 'Some Answer',
    visibility: EnumKnowledgeBaseVisibility.Published,
    translationMissing: false,
    internalAt: null,
    publishedAt: null,
    archivedAt: null,
    editedAt: null,
    editedBy: null,
    category: { id: convertToGraphQLId('KnowledgeBase::Category', 1), breadcrumb: [] },
    ...overrides,
  }) as KnowledgeBaseAnswerHeader

const renderDetails = (overrides: Partial<KnowledgeBaseAnswerHeader> = {}) =>
  renderComponent(KnowledgeBaseAnswerHeaderDetails, {
    props: { answer: answer(overrides) },
    store: true,
    router: true,
  })

describe('KnowledgeBaseAnswerHeaderDetails', () => {
  it.each([
    [EnumKnowledgeBaseVisibility.Draft, 'Draft'],
    [EnumKnowledgeBaseVisibility.Internal, 'Internal'],
    [EnumKnowledgeBaseVisibility.Published, 'Published'],
    [EnumKnowledgeBaseVisibility.Archived, 'Archived'],
  ])('labels the %s visibility badge', (visibility, label) => {
    const view = renderDetails({ visibility })

    expect(view.getByText(label)).toBeInTheDocument()
  })

  it('shows only the publication dates the answer actually carries', () => {
    const view = renderDetails({ publishedAt: '2026-08-01T10:00:00Z' })

    expect(view.getByText('Published at')).toBeInTheDocument()
    expect(view.queryByText('Internally published at')).not.toBeInTheDocument()
    expect(view.queryByText('Archived at')).not.toBeInTheDocument()
  })

  it('shows the internal and archival dates when they are set', () => {
    const view = renderDetails({
      visibility: EnumKnowledgeBaseVisibility.Archived,
      internalAt: '2026-07-01T10:00:00Z',
      archivedAt: '2026-08-05T10:00:00Z',
    })

    expect(view.getByText('Internally published at')).toBeInTheDocument()
    expect(view.getByText('Archived at')).toBeInTheDocument()
  })

  // What a user without knowledge base permission receives: the backend nulls
  //   the internal lifecycle, leaving the badge and the publication date.
  it('shows only the publication date for a public reader', () => {
    const view = renderDetails({
      publishedAt: '2026-08-01T10:00:00Z',
      internalAt: null,
      archivedAt: null,
      editedAt: null,
      editedBy: null,
    })

    expect(view.getByText('Published')).toBeInTheDocument()
    expect(view.getByText('Published at')).toBeInTheDocument()
    expect(view.queryByText('Internally published at')).not.toBeInTheDocument()
    expect(view.queryByText('Archived at')).not.toBeInTheDocument()
    expect(view.queryByText(/edited/)).not.toBeInTheDocument()
  })

  it('renders no edit chip without an edit date', () => {
    const view = renderDetails()

    expect(view.queryByText(/edited/)).not.toBeInTheDocument()
  })

  it('names the editor of the answer translation', () => {
    const view = renderDetails({
      editedAt: '2026-08-01T10:00:00Z',
      editedBy: {
        __typename: 'User',
        id: OTHER_USER_ID,
        firstname: 'Erika',
        lastname: 'Mustermann',
        fullname: 'Erika Mustermann',
      },
    })

    expect(view.getByText(/edited .* by Erika Mustermann/)).toBeInTheDocument()
  })

  it('addresses the current user as "me"', () => {
    mockUserCurrent({ id: CURRENT_USER_ID })

    const view = renderDetails({
      editedAt: '2026-08-01T10:00:00Z',
      editedBy: {
        __typename: 'User',
        id: CURRENT_USER_ID,
        firstname: 'Nicole',
        lastname: 'Braun',
        fullname: 'Nicole Braun',
      },
    })

    expect(view.getByText(/edited .* by me/)).toBeInTheDocument()
  })

  it('falls back to the bare date when the editor is not disclosed', () => {
    const view = renderDetails({ editedAt: '2026-08-01T10:00:00Z', editedBy: null })

    expect(view.getByText(/^edited /)).toBeInTheDocument()
    expect(view.queryByText(/ by /)).not.toBeInTheDocument()
  })
})
