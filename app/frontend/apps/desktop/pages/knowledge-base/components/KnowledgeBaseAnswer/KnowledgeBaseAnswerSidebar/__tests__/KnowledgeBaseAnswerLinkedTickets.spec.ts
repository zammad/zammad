// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import {
  EnumKnowledgeBaseVisibility,
  EnumLinkType,
  EnumTicketStateColorCode,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockLinkRemoveMutation,
  waitForLinkRemoveMutationCalls,
} from '#desktop/entities/link/graphql/mutations/linkRemove.mocks.ts'
import {
  mockLinkListQuery,
  waitForLinkListQueryCalls,
} from '#desktop/entities/link/graphql/queries/linkList.mocks.ts'

import KnowledgeBaseAnswerLinkedTickets from '../KnowledgeBaseAnswerLinkedTickets.vue'

import type { KnowledgeBaseAnswerHeader } from '../../../../types.ts'

const translationId = convertToGraphQLId('KnowledgeBase::Answer::Translation', 1)

const answer = {
  __typename: 'KnowledgeBaseAnswer',
  id: convertToGraphQLId('KnowledgeBase::Answer', 1),
  visibility: EnumKnowledgeBaseVisibility.Published,
  visibilitySchedules: [],
  internalAt: null,
  publishedAt: null,
  archivedAt: null,
  translation: {
    __typename: 'KnowledgeBaseAnswerTranslation',
    id: translationId,
    title: 'Some Answer',
    editedAt: null,
    editedBy: null,
    navigation: null,
    content: {
      __typename: 'KnowledgeBaseAnswerTranslationContent',
      bodyWithUrls: 'Et non omnis. Iste rerum ut. Reiciendis officia cumque.',
      id: convertToGraphQLId('KnowledgeBase::AnswerTranslationContent', 1),
    },
    kbLocale: {
      __typename: 'KnowledgeBaseLocale',
      id: convertToGraphQLId('KnowledgeBase::Locale', 1),
      systemLocale: { __typename: 'Locale', locale: 'en-us' },
    },
  },
  category: {
    __typename: 'KnowledgeBaseCategory',
    id: convertToGraphQLId('KnowledgeBase::Category', 1),
    breadcrumb: [],
  },
  tags: [],
  attachments: [],
  policy: { __typename: 'PolicyDefault', update: true, destroy: true },
} as KnowledgeBaseAnswerHeader

const linkedTicket = (
  internalId: number,
  title: string,
  stateColorCode: EnumTicketStateColorCode,
) => ({
  item: {
    __typename: 'Ticket' as const,
    id: convertToGraphQLId('Ticket', internalId),
    internalId,
    title,
    stateColorCode,
  },
  type: EnumLinkType.Normal,
})

const renderLinkedTickets = (
  props: { answer: KnowledgeBaseAnswerHeader; editable?: boolean } = { answer },
) =>
  renderComponent(KnowledgeBaseAnswerLinkedTickets, {
    props,
    store: true,
    router: true,
    form: true,
  })

describe('KnowledgeBaseAnswerLinkedTickets', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockLinkListQuery({
      linkList: [
        linkedTicket(
          1,
          'Printer on the second floor jams every other page',
          EnumTicketStateColorCode.Open,
        ),
        linkedTicket(
          2,
          'VPN disconnects after roughly ten minutes',
          EnumTicketStateColorCode.Pending,
        ),
      ],
    })
  })

  it('labels the section as related tickets', async () => {
    const view = renderLinkedTickets()

    expect(await view.findByText('Related tickets')).toBeInTheDocument()
  })

  // The links belong to the translation of the browsed locale, not to the answer.
  it('looks the links up by the answer translation', async () => {
    renderLinkedTickets()

    const calls = await waitForLinkListQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({ objectId: translationId, targetType: 'Ticket' })
  })

  it('renders a row per linked ticket, linking to it', async () => {
    const view = renderLinkedTickets()

    const links = await view.findAllByRole('link')

    expect(links).toHaveLength(2)

    expect(links[0]).toHaveAccessibleName('Printer on the second floor jams every other page')
    expect(links[0]).toHaveAttribute('href', '/tickets/1')

    expect(links[1]).toHaveAccessibleName('VPN disconnects after roughly ten minutes')
    expect(links[1]).toHaveAttribute('href', '/tickets/2')
  })

  it('shows the state of every linked ticket', async () => {
    const view = renderLinkedTickets()

    await view.findAllByRole('link')

    const states = view.getAllByRole('status')

    expect(states[0]).toHaveAttribute('aria-roledescription', '(ticket status: open)')
    expect(states[1]).toHaveAttribute('aria-roledescription', '(ticket status: pending)')
  })

  it('states that the answer has no links yet', async () => {
    mockLinkListQuery({ linkList: [] })

    const view = renderLinkedTickets()

    expect(await view.findByText('No links added yet.')).toBeInTheDocument()
  })

  // An answer without any translation has nothing links could hang off, so the
  //   lookup never runs and the section stays empty.
  it('lists no ticket for an answer without a translation', async () => {
    const view = renderLinkedTickets({
      answer: { ...answer, translation: null } as KnowledgeBaseAnswerHeader,
    })

    expect(await view.findByText('No links added yet.')).toBeInTheDocument()

    await waitFor(() => {
      expect(view.queryAllByRole('link')).toHaveLength(0)
    })
  })

  // The reader's sidebar renders the same section, so nothing may be actionable unless asked for.
  describe('when it is not editable', () => {
    it('offers no way to link or unlink', async () => {
      const view = renderLinkedTickets()

      await view.findAllByRole('link')

      expect(view.queryByRole('button', { name: 'Link ticket' })).not.toBeInTheDocument()
      expect(view.queryByRole('button', { name: 'Unlink ticket' })).not.toBeInTheDocument()
    })
  })

  describe('when it is editable', () => {
    // Both link mutations require `ticket.agent`, so an editor without any ticket permission is
    //   offered no way in rather than a button the mutation refuses - they still see what is linked.
    it('offers nothing to an editor without ticket permissions', async () => {
      mockPermissions(['knowledge_base.editor'])

      const view = renderLinkedTickets({ answer, editable: true })

      await view.findAllByRole('link')

      expect(view.queryByRole('button', { name: 'Link ticket' })).not.toBeInTheDocument()
      expect(view.queryByRole('button', { name: 'Unlink ticket' })).not.toBeInTheDocument()
    })

    it('offers linking and unlinking to an agent', async () => {
      const view = renderLinkedTickets({ answer, editable: true })

      expect(await view.findByRole('button', { name: 'Link ticket' })).toBeInTheDocument()
      expect(view.getAllByRole('button', { name: 'Unlink ticket' })).toHaveLength(2)
    })

    // Source and target are swapped on the way out, to stay consistent with what the old interface
    //   writes - and the object whose list this is has to be the *target*.
    it('unlinks a ticket from the answer translation', async () => {
      mockLinkRemoveMutation({ linkRemove: { success: true, errors: null } })

      const view = renderLinkedTickets({ answer, editable: true })

      await view.events.click((await view.findAllByRole('button', { name: 'Unlink ticket' }))[0])

      const calls = await waitForLinkRemoveMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        input: {
          sourceId: convertToGraphQLId('Ticket', 1),
          targetId: translationId,
          type: EnumLinkType.Normal,
        },
      })

      // And it leaves the list at once, which is the `linkList` cache write rather than a refetch.
      await waitFor(() => {
        expect(
          view.queryByText('Printer on the second floor jams every other page'),
        ).not.toBeInTheDocument()
      })

      expect(
        view.getByText('VPN disconnects after roughly ten minutes'),
        'the other link is untouched',
      ).toBeInTheDocument()
    })

    // A locale the answer has no translation in yet has nothing to hang a link off, and an empty
    //   section with no add button would look broken rather than explained.
    describe('with a locale that has no translation yet', () => {
      it('says so instead of offering to link', async () => {
        const view = renderLinkedTickets({
          answer: { ...answer, translation: null } as KnowledgeBaseAnswerHeader,
          editable: true,
        })

        expect(
          await view.findByText('Save the answer in this language before linking tickets to it.'),
        ).toBeInTheDocument()

        expect(view.queryByRole('button', { name: 'Link ticket' })).not.toBeInTheDocument()
      })
    })
  })
})
