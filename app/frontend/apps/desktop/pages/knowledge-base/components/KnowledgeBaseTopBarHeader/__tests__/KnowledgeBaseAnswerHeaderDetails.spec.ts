// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import KnowledgeBaseAnswerHeaderDetails from '../KnowledgeBaseAnswerHeaderDetails.vue'

import type { KnowledgeBaseAnswerHeader } from '../../../types.ts'

const CURRENT_USER_ID = convertToGraphQLId('User', 1)

// A date still ahead of the moment the test runs, which is what a scheduled change looks like on
//   the record: the same three columns, only not reached yet.
const inDays = (days: number) => new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString()
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

const renderDetails = (
  overrides: Partial<KnowledgeBaseAnswerHeader> = {},
  withTranslationWarning = false,
) =>
  renderComponent(KnowledgeBaseAnswerHeaderDetails, {
    props: { answer: answer(overrides), withTranslationWarning },
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

  // The badge carries no text of its own, so its accessible name is the whole warning - and the
  //   only thing a view spec could see it by.
  it('warns about a missing translation when asked to', () => {
    const view = renderDetails({ translationMissing: true }, true)

    expect(view.getByLabelText('No translation for this locale available')).toBeInTheDocument()
  })

  // The reader's header docks the same warning as an alert bar instead, and two of them would be
  //   one too many.
  it('leaves the warning out unless it is asked for', () => {
    const view = renderDetails({ translationMissing: true })

    expect(
      view.queryByLabelText('No translation for this locale available'),
    ).not.toBeInTheDocument()
  })

  it('does not warn about a translation that is there', () => {
    const view = renderDetails({ translationMissing: false }, true)

    expect(
      view.queryByLabelText('No translation for this locale available'),
    ).not.toBeInTheDocument()
  })

  it('shows only the publication dates the answer actually carries', () => {
    const view = renderDetails({ publishedAt: '2026-08-01T10:00:00Z' })

    // Twice: the visibility badge and the publication date badge.
    expect(view.getAllByText('Published')).toHaveLength(2)
    expect(view.queryByText('Internally published')).not.toBeInTheDocument()
    expect(view.queryByText('Archived')).not.toBeInTheDocument()
  })

  it('shows the internal and archival dates when they are set', () => {
    const view = renderDetails({
      visibility: EnumKnowledgeBaseVisibility.Archived,
      internalAt: '2026-07-01T10:00:00Z',
      archivedAt: '2026-08-05T10:00:00Z',
    })

    expect(view.getByText('Internally published')).toBeInTheDocument()
    // Twice: the visibility badge and the archival date badge.
    expect(view.getAllByText('Archived')).toHaveLength(2)
  })

  // A publication state is stored as the date it is reached at, so a date still ahead is a
  //   *scheduled* change. This strip says what the answer is - what it is going to become belongs
  //   to the editor's sidebar section, and to nobody else's view.
  it('leaves out a date the answer has not reached yet', () => {
    const view = renderDetails({
      visibility: EnumKnowledgeBaseVisibility.Draft,
      publishedAt: inDays(7),
    })

    expect(view.getByText('Draft')).toBeInTheDocument()
    expect(view.queryByText('Published')).not.toBeInTheDocument()
  })

  it('keeps the dates it has reached beside the ones it has not', () => {
    const view = renderDetails({
      internalAt: '2026-07-01T10:00:00Z',
      publishedAt: '2026-08-01T10:00:00Z',
      archivedAt: inDays(21),
    })

    expect(view.getByText('Internally published')).toBeInTheDocument()
    // Twice: the visibility badge and the publication date badge.
    expect(view.getAllByText('Published')).toHaveLength(2)
    expect(view.queryByText('Archived')).not.toBeInTheDocument()
  })

  // What a user without knowledge base permission receives: the backend nulls the internal
  //   lifecycle, leaving the badge and the publication date - which it only ever has reached.
  it('shows only the publication date for a public reader', () => {
    const view = renderDetails({
      publishedAt: '2026-08-01T10:00:00Z',
      internalAt: null,
      archivedAt: null,
      editedAt: null,
      editedBy: null,
    })

    // Twice: the visibility badge and the publication date badge.
    expect(view.getAllByText('Published')).toHaveLength(2)
    expect(view.queryByText('Internally published')).not.toBeInTheDocument()
    expect(view.queryByText('Archived')).not.toBeInTheDocument()
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
