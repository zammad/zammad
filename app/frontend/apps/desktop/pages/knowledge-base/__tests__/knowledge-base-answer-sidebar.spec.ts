// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import {
  EnumKnowledgeBaseSchedulableVisibility,
  EnumKnowledgeBaseVisibility,
  EnumLinkType,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswerQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswer.mocks.ts'
import {
  mockLinkListQuery,
  waitForLinkListQueryCalls,
} from '#desktop/entities/link/graphql/queries/linkList.mocks.ts'

const ANSWER_PATH = '/knowledge-base/locale/en-us/answer/1'

const ANSWER_TRANSLATION_ID = convertToGraphQLId('KnowledgeBase::Answer::Translation', 1)

// The extra hour keeps the relative label clear of the boundary the formatter floors at - exactly
//   two days from now reads as "in 1 day" by the time the assertion runs.
const IN_TWO_DAYS = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000 + 60 * 60 * 1000).toISOString()

// The header carries the same states and dates as badges, so every assertion below is scoped to the
//   sidebar - otherwise "Published" is found four times over and says nothing about this section.
const sidebarOf = async (view: Awaited<ReturnType<typeof visitView>>) =>
  within(await view.findByRole('complementary', { name: 'Content sidebar' }))

// `showFeedIcon`, because the sidebar's action menu offers the feed like the old interface did -
//   and an answer the user may not edit needs it to have a menu at all.
const mockKnowledgeBase = (showFeedIcon = false) =>
  mockKnowledgeBaseQuery({
    knowledgeBase: {
      id: convertToGraphQLId('KnowledgeBase', 1),
      translation: { title: 'My Knowledge Base' },
      iconset: 'default',
      isPubliclyAvailable: true,
      isVisiblePublicly: true,
      kbLocales: [
        {
          id: convertToGraphQLId('KnowledgeBase::Locale', 1),
          primary: true,
          systemLocale: { id: '1', locale: 'en-us', name: 'English (United States)' },
        },
      ],
      currentLocale: {
        id: convertToGraphQLId('KnowledgeBase::Locale', 1),
        systemLocale: { id: '1', locale: 'en-us' },
      },
      showFeedIcon,
    },
  })

describe('knowledge base answer sidebar', () => {
  beforeEach(() => {
    mockApplicationConfig({ kb_active_publicly: true })
    mockKnowledgeBase()
  })

  it('renders the content sidebar', async () => {
    const view = await visitView(ANSWER_PATH)

    expect(await view.findByRole('complementary', { name: 'Content sidebar' })).toBeInTheDocument()
  })

  // The answer's actions sit in the sidebar's header rather than in the top bar, per the design.
  //   That the edit action actually opens the edit view is covered where the reader's floating
  //   toolbar offers the same one (knowledge-base-answer-header.spec.ts) - here it is about which
  //   entries the menu holds.
  describe('the action menu', () => {
    const openMenu = async (view: Awaited<ReturnType<typeof visitView>>) => {
      const sidebar = await sidebarOf(view)

      await view.events.click(sidebar.getByRole('button', { name: 'Additional actions' }))

      return within(await view.findByRole('menu'))
    }

    it('offers editing an answer the user may update', async () => {
      mockPermissions(['knowledge_base.editor'])
      mockKnowledgeBaseAnswerQuery({
        // Schedules explicitly, like every other example here: two auto-mocked ones can share a
        //   visibility, which the sidebar's list keys by.
        knowledgeBaseAnswer: { policy: { update: true, destroy: true }, visibilitySchedules: [] },
      })

      const view = await visitView(ANSWER_PATH)

      expect(
        (await openMenu(view)).getByRole('button', { name: 'Edit answer' }),
      ).toBeInTheDocument()
    })

    // Gated per record: the global editor permission says nothing about the subtree the answer
    //   lives in, and a control the mutation refuses is worse than none.
    it('does not offer editing an answer the user may not update', async () => {
      mockPermissions(['knowledge_base.editor'])
      // With the feed entry on, so there is still a menu to look into: an answer offering no action
      //   at all gets no menu button.
      mockKnowledgeBase(true)
      mockKnowledgeBaseAnswerQuery({
        knowledgeBaseAnswer: { policy: { update: false, destroy: false }, visibilitySchedules: [] },
      })

      const view = await visitView(ANSWER_PATH)
      const menu = await openMenu(view)

      // The feed entry is still on offer, so the menu is genuinely open and merely has no edit
      //   entry in it.
      expect(menu.getByRole('button', { name: 'Set up RSS feed' })).toBeInTheDocument()
      expect(menu.queryByRole('button', { name: 'Edit answer' })).not.toBeInTheDocument()
    })
  })

  // The three publication dates are the ones the answer has *reached*. A date still ahead is a
  //   scheduled change, and the reading view must not present one as something that happened.
  describe('publication dates', () => {
    it('lists a date the answer has reached', async () => {
      mockKnowledgeBaseAnswerQuery({
        knowledgeBaseAnswer: {
          visibility: EnumKnowledgeBaseVisibility.Published,
          internalAt: null,
          publishedAt: '2026-08-01T10:00:00Z',
          archivedAt: null,
          visibilitySchedules: [],
        },
      })

      const view = await visitView(ANSWER_PATH)
      const sidebar = await sidebarOf(view)

      // Twice: the visibility row's value and the publication date's own label.
      expect(sidebar.getAllByText('Published')).toHaveLength(2)
    })

    it('leaves out a date the answer has not reached yet', async () => {
      mockKnowledgeBaseAnswerQuery({
        knowledgeBaseAnswer: {
          visibility: EnumKnowledgeBaseVisibility.Draft,
          internalAt: null,
          publishedAt: IN_TWO_DAYS,
          archivedAt: null,
          visibilitySchedules: [],
        },
      })

      const view = await visitView(ANSWER_PATH)
      const sidebar = await sidebarOf(view)

      expect(sidebar.getByText('Draft')).toBeInTheDocument()
      expect(sidebar.queryByText('Published')).not.toBeInTheDocument()
    })
  })

  // What the answer is going to become is editorial, and this is the reading view: an editor is
  //   shown it, read-only, and everybody else is not shown it at all.
  describe('scheduled visibility', () => {
    const mockScheduledAnswer = (update: boolean) =>
      mockKnowledgeBaseAnswerQuery({
        knowledgeBaseAnswer: {
          visibility: EnumKnowledgeBaseVisibility.Draft,
          internalAt: null,
          publishedAt: IN_TWO_DAYS,
          archivedAt: null,
          visibilitySchedules: [
            {
              visibility: EnumKnowledgeBaseSchedulableVisibility.Published,
              scheduledAt: IN_TWO_DAYS,
            },
          ],
          policy: { update, destroy: update },
        },
      })

    it('shows the scheduled changes to an editor, without a way to remove them', async () => {
      mockScheduledAnswer(true)

      const view = await visitView(ANSWER_PATH)
      const sidebar = await sidebarOf(view)

      expect(sidebar.getByText('Scheduled visibility')).toBeInTheDocument()
      expect(sidebar.getByText('in 2 days')).toBeInTheDocument()
      expect(
        sidebar.queryByRole('button', { name: 'Remove this scheduled visibility change' }),
      ).not.toBeInTheDocument()
    })

    // The backend withholds the field from a non-editor as well (KnowledgeBase::AnswerPolicy#show?
    //   denies `visibility_schedules` outside editor access), so this combination cannot occur for
    //   real - the gate is what keeps the section, and its empty state, out of a reader's sidebar
    //   whatever the payload says.
    it('hides them from a user who may not edit the answer', async () => {
      mockScheduledAnswer(false)

      const view = await visitView(ANSWER_PATH)
      const sidebar = await sidebarOf(view)

      // The sidebar rendered, so the section is missing by its gate rather than by an empty page.
      expect(sidebar.getByText('Visibility')).toBeInTheDocument()
      expect(sidebar.queryByText('Scheduled visibility')).not.toBeInTheDocument()
    })
  })

  it('lists the tags of the answer', async () => {
    mockKnowledgeBaseAnswerQuery({ knowledgeBaseAnswer: { tags: ['vip', 'billing'] } })

    const view = await visitView(ANSWER_PATH)

    expect(await view.findByRole('link', { name: 'vip' })).toHaveAttribute(
      'href',
      `/desktop/search/${encodeURI('tags:"vip"')}?entity=Ticket`,
    )
    expect(view.getByRole('link', { name: 'billing' })).toBeInTheDocument()
  })

  it('states that the answer has no tags yet', async () => {
    mockKnowledgeBaseAnswerQuery({ knowledgeBaseAnswer: { tags: [] } })

    const view = await visitView(ANSWER_PATH)

    expect(await view.findByText('No tags added yet.')).toBeInTheDocument()
  })

  it('lists the tickets linked to the answer translation', async () => {
    mockKnowledgeBaseAnswerQuery({
      knowledgeBaseAnswer: { translation: { id: ANSWER_TRANSLATION_ID } },
    })

    mockLinkListQuery({
      linkList: [
        {
          item: {
            __typename: 'Ticket',
            id: convertToGraphQLId('Ticket', 1),
            internalId: 1,
            title: 'Printer on the second floor jams every other page',
          },
          type: EnumLinkType.Normal,
        },
      ],
    })

    const view = await visitView(ANSWER_PATH)

    expect(await view.findByText('Related tickets')).toBeInTheDocument()
    expect(
      await view.findByRole('link', { name: 'Printer on the second floor jams every other page' }),
    ).toHaveAttribute('href', '/desktop/tickets/1')

    const calls = await waitForLinkListQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      objectId: ANSWER_TRANSLATION_ID,
      targetType: 'Ticket',
    })
  })

  it('states that the answer has no linked tickets yet', async () => {
    mockLinkListQuery({ linkList: [] })

    const view = await visitView(ANSWER_PATH)

    expect(await view.findByText('No links added yet.')).toBeInTheDocument()
  })
})
