// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getGraphQLMockCalls, waitForGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import {
  mockFormUpdaterQuery,
  waitForFormUpdaterQueryCalls,
} from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import {
  mockTagAssignmentRemoveMutationError,
  waitForTagAssignmentRemoveMutationCalls,
} from '#shared/entities/tags/graphql/mutations/assignment/remove.mocks.ts'
import {
  EnumFormUpdaterId,
  EnumKnowledgeBaseAnswerScreenBehavior,
  EnumKnowledgeBaseVisibility,
  EnumTaskbarApp,
  EnumTaskbarEntity,
  EnumTaskbarEntityAccess,
  EnumUserErrorException,
  type KnowledgeBaseAnswerQuery,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import {
  mockKnowledgeBaseAnswerDeleteMutation,
  waitForKnowledgeBaseAnswerDeleteMutationCalls,
} from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseAnswerDelete.mocks.ts'
import { KnowledgeBaseAnswerUpdateDocument } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseAnswerUpdate.api.ts'
import {
  mockKnowledgeBaseAnswerUpdateMutation,
  waitForKnowledgeBaseAnswerUpdateMutationCalls,
} from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseAnswerUpdate.mocks.ts'
import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import {
  mockKnowledgeBaseAnswerQuery,
  waitForKnowledgeBaseAnswerQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswer.mocks.ts'
import { KnowledgeBaseAnswerLiveUserUpdatesDocument } from '#desktop/entities/knowledge-base/graphql/subscriptions/knowledgeBaseAnswerLiveUserUpdates.api.ts'
import { getKnowledgeBaseAnswerLiveUserUpdatesSubscriptionHandler } from '#desktop/entities/knowledge-base/graphql/subscriptions/knowledgeBaseAnswerLiveUserUpdates.mocks.ts'
import { getKnowledgeBaseAnswerUpdatesSubscriptionHandler } from '#desktop/entities/knowledge-base/graphql/subscriptions/knowledgeBaseAnswerUpdates.mocks.ts'
import { UserCurrentTaskbarItemDeleteDocument } from '#desktop/entities/user/current/graphql/mutations/userCurrentTaskbarItemDelete.api.ts'
import { waitForUserCurrentTaskbarItemDeleteMutationCalls } from '#desktop/entities/user/current/graphql/mutations/userCurrentTaskbarItemDelete.mocks.ts'
import { mockUserCurrentTaskbarItemListQuery } from '#desktop/entities/user/current/graphql/queries/userCurrentTaskbarItemList.mocks.ts'

const LOCALE = 'en-us'
const ANSWER_INTERNAL_ID = 5
const ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', ANSWER_INTERNAL_ID)
const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const CONTENT_ID = convertToGraphQLId(
  'KnowledgeBase::Answer::Translation::Content',
  ANSWER_INTERNAL_ID,
)
const TASKBAR_ITEM_ID = convertToGraphQLId('Taskbar', 1)
const TITLE = 'Some Knowledge Base Answer'

type Answer = NonNullable<KnowledgeBaseAnswerQuery['knowledgeBaseAnswer']>

const mockKnowledgeBase = () =>
  mockKnowledgeBaseQuery({
    knowledgeBase: {
      id: convertToGraphQLId('KnowledgeBase', 1),
      title: 'My Knowledge Base',
      iconset: 'default',
      isPubliclyAvailable: false,
      isVisiblePublicly: false,
      kbLocales: [
        {
          id: convertToGraphQLId('KnowledgeBase::Locale', 1),
          primary: true,
          systemLocale: { id: '1', locale: 'en-us', name: 'English (United States)' },
        },
        {
          id: convertToGraphQLId('KnowledgeBase::Locale', 2),
          primary: false,
          systemLocale: { id: '2', locale: 'de-de', name: 'Deutsch' },
        },
      ],
      currentLocale: {
        id: convertToGraphQLId('KnowledgeBase::Locale', 1),
        systemLocale: { id: '1', locale: 'en-us' },
      },
    },
  })

// The tab has to exist for the view to render its content at all - LayoutTaskbarTabContent
//   waits for the taskbar entry of the route's entity key, and gates it on `entityAccess`.
const mockTaskbarTab = () =>
  mockUserCurrentTaskbarItemListQuery({
    userCurrentTaskbarItemList: [
      {
        __typename: 'UserTaskbarItem',
        id: TASKBAR_ITEM_ID,
        key: `KnowledgeBase__Answer-${ANSWER_INTERNAL_ID}-${LOCALE}`,
        callback: EnumTaskbarEntity.KnowledgeBaseAnswerEdit,
        entityAccess: EnumTaskbarEntityAccess.Granted,
        entity: null,
      },
    ],
  })

const mockAnswer = (overrides: Partial<Answer> = {}) =>
  mockKnowledgeBaseAnswerQuery({
    knowledgeBaseAnswer: {
      id: ANSWER_ID,
      title: TITLE,
      content: {
        __typename: 'KnowledgeBaseAnswerTranslationContent',
        id: CONTENT_ID,
        bodyWithUrls: '<p>Some text.</p>',
      },
      visibility: EnumKnowledgeBaseVisibility.Published,
      translationMissing: false,
      internalAt: null,
      publishedAt: '2026-08-01T10:00:00Z',
      archivedAt: null,
      editedAt: null,
      editedBy: null,
      navigation: null,
      tags: [],
      attachments: [],
      category: {
        id: CATEGORY_ID,
        breadcrumb: [
          {
            id: CATEGORY_ID,
            title: 'Hardware',
            categoryIcon: 'folder',
            visibility: EnumKnowledgeBaseVisibility.Published,
          },
        ],
      },
      ...overrides,
    },
  } as KnowledgeBaseAnswerQuery)

const CATEGORY_OPTIONS = [
  { value: 1, label: 'Hardware' },
  { value: 2, label: 'Software' },
]

// What the real updater answers with on the first round trip: the answer's own values
//   (FormUpdater::Updater::KnowledgeBase::Answer::Edit#initial_values), and the category options
//   on every one (FormUpdater::Updater::KnowledgeBase::Answer::Concerns::HasCategoryField).
const mockAnswerEditFormUpdater = () =>
  mockFormUpdaterQuery(({ meta }) => ({
    formUpdater: {
      fields: {
        categoryId: {
          options: CATEGORY_OPTIONS,
          required: true,
          ...(meta.initial ? { initialValue: 1 } : {}),
        },
        ...(meta.initial
          ? {
              title: { initialValue: TITLE },
              body: { initialValue: '<p>Some text.</p>' },
              visibility: { initialValue: EnumKnowledgeBaseVisibility.Published },
            }
          : {}),
      },
    },
  }))

const visitEditView = (
  locale = LOCALE,
  answerInternalId = ANSWER_INTERNAL_ID,
  options: Parameters<typeof visitView>[1] = {},
) => {
  mockTaskbarTab()

  return visitView(`/knowledge-base/locale/${locale}/answer/${answerInternalId}/edit`, options)
}

describe('knowledge base answer edit', () => {
  beforeEach(() => {
    mockApplicationConfig({ kb_active: true })
    mockPermissions(['knowledge_base.editor'])
    mockKnowledgeBase()
    mockAnswer()
    mockAnswerEditFormUpdater()
  })

  it('seeds the form from the answer', async () => {
    const view = await visitEditView()

    expect(await view.findByDisplayValue(TITLE)).toBeInTheDocument()
    expect(view.getByLabelText('Text')).toBeInTheDocument()
  })

  // An answer with no translation in the edited locale is *shown* with the primary locale's title
  //   and body (the query falls back, which is what the breadcrumb and the reader need), but the
  //   form must not be seeded from that fallback: a save would store the foreign text as this
  //   translation, and the tab would count as changed - draft stored, editor listed as editing -
  //   before anybody typed a word.
  it('opens a locale without its own translation on empty fields', async () => {
    mockAnswer({ translationMissing: true })

    // What the real updater answers for a locale that has no translation yet: empty, not absent
    //   (`stored_title`/`stored_body` of FormUpdater::Updater::KnowledgeBase::Answer::Edit) - and
    //   only for a name the form did not already send a value for, which is the rule that makes a
    //   seeded fallback win over it (FormUpdater::Concerns::ProvidesInitialValues: `next if
    //   data[name].present?`).
    mockFormUpdaterQuery(({ meta, data }) => ({
      formUpdater: {
        fields: {
          categoryId: {
            options: CATEGORY_OPTIONS,
            required: true,
            ...(meta.initial ? { initialValue: 1 } : {}),
          },
          ...(meta.initial
            ? {
                ...(data.title ? {} : { title: { initialValue: '' } }),
                ...(data.body ? {} : { body: { initialValue: '' } }),
                visibility: { initialValue: EnumKnowledgeBaseVisibility.Published },
              }
            : {}),
        },
      },
    }))

    const view = await visitEditView()

    // Settled, so an empty title is what the form opened with rather than a round trip still out.
    await view.findByRole('radio', { name: 'Public' })

    expect(view.getByLabelText('Title')).toHaveValue('')
    expect(view.queryByDisplayValue(TITLE)).not.toBeInTheDocument()
    expect(view.queryByRole('button', { name: 'Discard changes' })).not.toBeInTheDocument()
  })

  // The whole breadcrumb - category path and title alike - comes from the stored answer, not the
  //   form. Unlike the create view (whose draft has nothing stored for its heading to read, so it
  //   follows what is typed), an edited answer already has a heading: only a save, and the refetch
  //   it triggers, changes it.
  it('renders the breadcrumb as the heading, from the stored answer - not the form', async () => {
    const view = await visitEditView()

    expect(await view.findAllByRole('heading', { name: TITLE })).not.toHaveLength(0)

    // Settled, so there is no second "initial" round trip left to land mid-edit and overwrite
    //   what is typed/picked below.
    await view.findByRole('radio', { name: 'Public' })

    const title = view.getByDisplayValue(TITLE)
    await view.events.clear(title)
    await view.events.type(title, 'A new title')

    await view.events.click(view.getByLabelText('Category'))
    const softwareOption = await view.findByRole('option', { name: 'Software' })
    await view.events.click(softwareOption.firstChild as Element)

    expect(
      view.getAllByRole('heading', { name: TITLE }),
      'still the stored title, unaffected by what is typed',
    ).not.toHaveLength(0)
    expect(view.queryByRole('heading', { name: 'A new title' })).not.toBeInTheDocument()

    expect(
      view.getByTestId('knowledge-base-header-full'),
      'still the stored category, unaffected by what is picked',
    ).toHaveTextContent('Hardware')
  })

  // The reader steps through the answers of a category; an edit tab holding unsaved work must not
  //   offer to walk away from it - not even with the data for it right there. And with no stepper
  //   it should not ask for the neighbours at all: `withNavigation: false` also switches off the
  //   two prefetches their links warm (useKnowledgeBaseAnswer.ts).
  it('does not offer the answer stepper, and does not ask for the neighbours', async () => {
    mockAnswer({
      navigation: {
        __typename: 'KnowledgeBaseAnswerNavigation',
        index: 1,
        totalCount: 3,
        previousAnswer: {
          __typename: 'KnowledgeBaseAnswer',
          id: convertToGraphQLId('KnowledgeBase::Answer', ANSWER_INTERNAL_ID - 1),
          title: 'The one before',
        },
        nextAnswer: {
          __typename: 'KnowledgeBaseAnswer',
          id: convertToGraphQLId('KnowledgeBase::Answer', ANSWER_INTERNAL_ID + 1),
          title: 'The one after',
        },
      },
    })

    const view = await visitEditView()

    await view.findByDisplayValue(TITLE)

    expect(view.queryByRole('navigation', { name: 'Answer navigation' })).not.toBeInTheDocument()

    const calls = await waitForKnowledgeBaseAnswerQueryCalls()

    expect(calls.at(-1)?.variables).toEqual(expect.objectContaining({ withNavigation: false }))
  })

  // Everything the header shows comes from the stored answer, so it has to skeleton until the
  //   answer is there - like the reader's header does. Rendering as soon as the knowledge base
  //   store had resolved put a breadcrumb with nothing but the knowledge base root on screen and
  //   replaced it a moment later.
  it('skeletons the header until the answer is there', async () => {
    const view = await visitEditView()

    expect(
      view.queryAllByRole('navigation', { name: 'Knowledge base navigation' }),
      'no half-filled breadcrumb before the answer has arrived',
    ).toHaveLength(0)

    await view.findByDisplayValue(TITLE)

    expect(
      view.queryAllByRole('navigation', { name: 'Knowledge base navigation' }),
    ).not.toHaveLength(0)
  })

  // `CommonLoader` animates its child through a `Transition`, which can only animate a single
  //   element - and `Form` renders two root nodes (its initial loading spinner beside the form).
  //   Vue then warns on every render of the view. Transitions are stubbed by default, so this has
  //   to render them for real to see it at all.
  it('renders the form without a transition warning', async () => {
    const view = await visitEditView(LOCALE, ANSWER_INTERNAL_ID, {
      global: { stubs: { transition: false } },
    })

    await view.findByDisplayValue(TITLE)

    // The suite fails on any warning anyway (vitest.setup.ts), but say it here: this example
    //   exists for that one assertion and for nothing else.
    expect(console.warn).not.toHaveBeenCalled()
  })

  // The field sits in the header, above the fields it belongs to - so it has to measure like
  //   them: it was capped at the wider browse-view column and hung over the form below it.
  it('lines the header title field up with the form column', async () => {
    const view = await visitEditView()

    expect((await view.findByLabelText('Title')).closest('.max-w-270')).not.toBeNull()
    expect(view.getByLabelText('Text').closest('.max-w-270')).not.toBeNull()
  })

  // The field is declared once (useAnswerFormSchema.ts) and teleported into the header - proof it
  //   actually lands there, rather than in the content column it used to render in.
  it('renders the title field inside the header, not the content column', async () => {
    const view = await visitEditView()

    const header = view.getByTestId('knowledge-base-header-full')

    expect(header).toContainElement(await view.findByDisplayValue(TITLE))
  })

  // The badges come from the stored answer too, and for the same reason: `KnowledgeBaseAnswerUpdate`
  //   only replaces them once the save round trip refetches the answer. Two "Published" texts are
  //   expected already - the visibility badge and the separate "published … ago" chip - so the
  //   proof that the badge row ignores the field is the absence of a "Draft" badge, not a count.
  it('shows the badges from the stored answer, unaffected by the form', async () => {
    const view = await visitEditView()

    const header = view.getByTestId('knowledge-base-header-full')

    expect(await within(header).findAllByText('Published')).not.toHaveLength(0)

    await view.events.click(await view.findByRole('radio', { name: 'Draft' }))

    expect(within(header).getAllByText('Published')).not.toHaveLength(0)
    expect(within(header).queryByText('Draft')).not.toBeInTheDocument()
  })

  // The sidebar rewrites the answer in the cache before the mutation has answered, so a click
  //   reacts at once - which is why a failed call has to put it back. Nothing else would: the
  //   answer's subscription only fires when tagging actually touches the record, and a call that
  //   failed touches nothing. The entity is the one the reader's sidebar renders from as well.
  it('puts a tag back when removing it fails', async () => {
    mockAnswer({ tags: ['vip'] })
    mockTagAssignmentRemoveMutationError('Forbidden', { type: GraphQLErrorTypes.Forbidden })

    const view = await visitEditView()

    const sidebar = await view.findByRole('complementary', { name: 'Content sidebar' })

    await view.events.click(await within(sidebar).findByRole('button', { name: 'Remove this tag' }))

    // Gone the moment it is clicked ...
    await waitFor(() => {
      expect(within(sidebar).queryByText('vip')).not.toBeInTheDocument()
    })

    await waitForTagAssignmentRemoveMutationCalls()

    // ... and back once the call has failed.
    expect(await within(sidebar).findByText('vip')).toBeInTheDocument()
  })

  // Not a form field: tags are written straight onto the answer, so they are neither part of the
  //   auto-saved draft nor of "Discard changes" - the same as the linked tickets.
  it('manages the tags from the sidebar rather than from the form', async () => {
    const view = await visitEditView()

    const sidebar = await view.findByRole('complementary', { name: 'Content sidebar' })

    expect(within(sidebar).getByRole('button', { name: 'Add tag' })).toBeInTheDocument()
  })

  it('offers no title field in the sidebar - only visibility, timing and category', async () => {
    const view = await visitEditView()

    await view.findByDisplayValue(TITLE)

    const sidebar = await view.findByRole('complementary', { name: 'Content sidebar' })

    expect(sidebar).toContainElement(view.getByLabelText('Visibility'))
    expect(sidebar).toContainElement(view.getByLabelText('Category'))
    expect(
      view.queryByLabelText('Tags'),
      'tags are edited from the sidebar, not this form',
    ).not.toBeInTheDocument()
  })

  it('tells the form updater which taskbar to store the draft in', async () => {
    await visitEditView()

    const calls = await waitForFormUpdaterQueryCalls()

    expect(calls.at(-1)?.variables).toMatchObject({
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterKnowledgeBaseAnswerEdit,
      meta: {
        additionalData: {
          taskbarId: TASKBAR_ITEM_ID,
          locale: LOCALE,
        },
      },
    })
  })

  // The answer's own files are what the form opens with, so the updater sends them as the field's
  //   *initial* value (FormUpdater::ApplyValue::FormId with `as_initial`). Sent as a plain `value`
  //   they would leave the field without a baseline - FormKit captures `_init` synchronously at node
  //   creation and nothing backfills it - and the form would be dirty before anybody touched it, on
  //   every answer that has an attachment.
  it('opens clean on an answer that has attachments', async () => {
    mockAnswer({
      attachments: [
        {
          __typename: 'StoredFile',
          id: convertToGraphQLId('Store', 1),
          internalId: 1,
          name: 'handbook.pdf',
          size: 1234,
          type: 'application/pdf',
          preferences: {},
        },
      ],
    } as never)

    mockFormUpdaterQuery(({ meta }) => ({
      formUpdater: {
        fields: {
          categoryId: {
            options: CATEGORY_OPTIONS,
            required: true,
            ...(meta.initial ? { initialValue: 1 } : {}),
          },
          ...(meta.initial
            ? {
                title: { initialValue: TITLE },
                body: { initialValue: '<p>Some text.</p>' },
                visibility: { initialValue: EnumKnowledgeBaseVisibility.Published },
                attachments: {
                  initialValue: [
                    {
                      id: convertToGraphQLId('Store', 1),
                      name: 'handbook.pdf',
                      size: 1234,
                      type: 'application/pdf',
                    },
                  ],
                },
              }
            : {}),
        },
      },
    }))

    const view = await visitEditView()

    await view.findByDisplayValue(TITLE)
    await view.findByRole('radio', { name: 'Public' })

    // Proof the seed actually landed - without it the assertion below would pass simply because
    //   no attachment rendered at all.
    const files = view.getByRole('list', { name: 'Attached files' })
    expect(within(files).getAllByRole('listitem')).toHaveLength(1)

    expect(view.queryByRole('button', { name: 'Discard changes' })).not.toBeInTheDocument()
  })

  // The create view's own pair: with nothing to give up on, leaving needs no question asked.
  it('offers going back until something is changed, and discarding afterwards', async () => {
    const view = await visitEditView()

    await view.findByDisplayValue(TITLE)

    expect(view.getByRole('button', { name: 'Cancel & go back' })).toBeInTheDocument()
    expect(view.queryByRole('button', { name: 'Discard changes' })).not.toBeInTheDocument()
    expect(view.getByRole('button', { name: 'Update' })).toBeInTheDocument()

    await view.events.type(view.getByDisplayValue(TITLE), '!')

    expect(await view.findByRole('button', { name: 'Discard changes' })).toBeInTheDocument()
    expect(view.queryByRole('button', { name: 'Cancel & go back' })).not.toBeInTheDocument()
  })

  // Giving up on the changes closes the tab, like in the create view - the stored answer is
  //   untouched, it is read in its own view, and an edit tab for it can be opened again at any
  //   time.
  it('closes the tab when the changes are discarded', async () => {
    const view = await visitEditView()

    // Settled, so the discard is not racing the initial round trip.
    await view.findByRole('radio', { name: 'Public' })

    await view.events.type(view.getByDisplayValue(TITLE), '!')

    const router = getTestRouter()
    router.mockMethods()

    await view.events.click(await view.findByRole('button', { name: 'Discard changes' }))

    const dialog = await view.findByRole('dialog', { name: 'Unsaved changes' })
    await view.events.click(within(dialog).getByRole('button', { name: 'Discard changes' }))

    const calls = await waitForUserCurrentTaskbarItemDeleteMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({ id: TASKBAR_ITEM_ID })

    // Asserted on the navigation rather than by letting it happen: the history is shared by every
    //   example in this file, and actually leaving puts an `/edit` entry where the screen behavior
    //   examples below read one (`history.state.back`).
    //
    // The root, because nothing was visited before this tab - with something to go back to the
    //   walker goes back there instead, which is its own behaviour rather than this view's.
    expect(router.push).toHaveBeenCalledWith('/')

    router.restoreMethods()
  })

  describe('deleting the answer', () => {
    it('offers deleting when the policy grants it', async () => {
      mockAnswer({ policy: { __typename: 'PolicyDefault', update: true, destroy: true } })

      const view = await visitEditView()

      const sidebar = await view.findByRole('complementary', { name: 'Content sidebar' })

      await view.events.click(within(sidebar).getByRole('button', { name: 'Action menu button' }))

      expect(
        within(await view.findByRole('menu')).getByRole('button', { name: 'Delete answer' }),
      ).toBeInTheDocument()
    })

    it('does not offer deleting when the policy denies it', async () => {
      mockAnswer({ policy: { __typename: 'PolicyDefault', update: true, destroy: false } })

      const view = await visitEditView()

      await view.findByDisplayValue(TITLE)

      const sidebar = await view.findByRole('complementary', { name: 'Content sidebar' })

      expect(
        within(sidebar).queryByRole('button', { name: 'Action menu button' }),
      ).not.toBeInTheDocument()
    })

    it('deletes the answer and returns to its category', async () => {
      mockAnswer({ policy: { __typename: 'PolicyDefault', update: true, destroy: true } })
      mockKnowledgeBaseAnswerDeleteMutation(() => ({
        knowledgeBaseAnswerDelete: { success: true, errors: null },
      }))

      const view = await visitEditView()

      const sidebar = await view.findByRole('complementary', { name: 'Content sidebar' })

      const router = getTestRouter()
      router.mockMethods()

      await view.events.click(within(sidebar).getByRole('button', { name: 'Action menu button' }))
      await view.events.click(
        within(await view.findByRole('menu')).getByRole('button', { name: 'Delete answer' }),
      )

      const dialog = await view.findByRole('dialog')

      expect(
        within(dialog).getByText(`Do you really want to delete "${TITLE}"?`),
      ).toBeInTheDocument()

      await view.events.click(within(dialog).getByRole('button', { name: 'Delete object' }))

      const deleteCalls = await waitForKnowledgeBaseAnswerDeleteMutationCalls()
      expect(deleteCalls.at(-1)?.variables).toEqual({ answerId: ANSWER_ID })

      expect(
        await view.findByText('Knowledge base answer deleted successfully.'),
      ).toBeInTheDocument()

      expect(router.replace).toHaveBeenCalledWith({
        name: 'KnowledgeBaseCategory',
        params: { localeCode: LOCALE, categoryInternalId: getIdFromGraphQLId(CATEGORY_ID) },
      })

      // The tab is not closed from here: `HasTaskbars` destroyed it inside the delete, and its
      //   removal arrives as the taskbar list subscription's `removeItem`. Asking the backend to
      //   delete it a second time would only earn a not-found behind the success notification.
      expect(getGraphQLMockCalls(UserCurrentTaskbarItemDeleteDocument)).toHaveLength(0)

      router.restoreMethods()
    })
  })

  // A publication scheduled for later is *not* what this form deals with: it carries the state the
  //   answer is in right now, and the schedule belongs to a sidebar widget of its own. The form must
  //   therefore neither offer a date nor send one - sending the current state together with a
  //   timestamp is what would cancel the schedule
  //   (Service::KnowledgeBase::Answer::Base#scheduled_publication?).
  describe('with a publication scheduled for later', () => {
    beforeEach(() => {
      // Still a draft: `publishedAt` lies in the future, so CanBePublished has not reached it yet.
      mockAnswer({
        visibility: EnumKnowledgeBaseVisibility.Draft,
        publishedAt: '2027-01-15T10:00:00Z',
      })

      mockFormUpdaterQuery(({ meta }) => ({
        formUpdater: {
          fields: {
            categoryId: {
              options: CATEGORY_OPTIONS,
              required: true,
              ...(meta.initial ? { initialValue: 1 } : {}),
            },
            ...(meta.initial
              ? {
                  title: { initialValue: TITLE },
                  body: { initialValue: '<p>Some text.</p>' },
                  // The answer's current state, which is what the real updater seeds.
                  visibility: { initialValue: EnumKnowledgeBaseVisibility.Draft },
                }
              : {}),
          },
        },
      }))
    })

    it('opens on the state the answer is still in', async () => {
      const view = await visitEditView()

      expect(await view.findByRole('radio', { name: 'Draft' })).toHaveAttribute(
        'aria-checked',
        'true',
      )
    })

    it('offers no timing field to reschedule it with', async () => {
      const view = await visitEditView()

      await view.findByRole('radio', { name: 'Draft' })

      expect(view.queryByText('Timing')).not.toBeInTheDocument()
      expect(view.queryByRole('radio', { name: 'Schedule for' })).not.toBeInTheDocument()
    })

    it('submits the state without a date, leaving the schedule alone', async () => {
      mockKnowledgeBaseAnswerUpdateMutation({
        knowledgeBaseAnswerUpdate: { answer: null, errors: null },
      })

      const view = await visitEditView()

      await view.findByRole('radio', { name: 'Draft' })

      await view.events.click(view.getByRole('radio', { name: 'Internal' }))
      await view.events.click(view.getByRole('button', { name: 'Update' }))

      const calls = await waitForKnowledgeBaseAnswerUpdateMutationCalls()
      const variables = calls.at(-1)?.variables as { input: Record<string, unknown> }

      expect(variables.input.visibility).toBe(EnumKnowledgeBaseVisibility.Internal)
    })
  })

  describe('saving the answer', () => {
    const submitEdit = async () => {
      mockKnowledgeBaseAnswerUpdateMutation({
        knowledgeBaseAnswerUpdate: {
          answer: {
            id: ANSWER_ID,
            title: 'Updated title',
            content: {
              __typename: 'KnowledgeBaseAnswerTranslationContent',
              id: CONTENT_ID,
              bodyWithUrls: '<p>Some text.</p>',
            },
            visibility: EnumKnowledgeBaseVisibility.Published,
            translationMissing: false,
            internalAt: null,
            publishedAt: '2026-08-01T10:00:00Z',
            archivedAt: null,
            editedAt: '2026-08-26T10:00:00Z',
            editedBy: null,
            tags: [],
            attachments: [],
            category: {
              id: CATEGORY_ID,
              breadcrumb: [{ id: CATEGORY_ID, title: 'Hardware' }],
            },
          },
          errors: null,
        },
      } as never)

      const view = await visitEditView()

      // Settled, so there is no second "initial" round trip left to land mid-edit and overwrite
      //   what is typed below.
      await view.findByRole('radio', { name: 'Public' })

      const title = view.getByDisplayValue(TITLE)
      await view.events.clear(title)
      await view.events.type(title, 'Updated title')

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      return view
    }

    // The baseline the concurrency guard needs: the files as this tab opened, so the backend can tell
    //   a foreign attachment change from this editor's own. Read at load time on purpose - the answer
    //   is live-updated by its subscription, so reading it at save time would already show their
    //   change and compare equal.
    it('submits the attachments the tab was opened with', async () => {
      await submitEdit()

      const calls = await waitForKnowledgeBaseAnswerUpdateMutationCalls()
      const variables = calls.at(-1)?.variables as { meta?: Record<string, unknown> }

      expect(variables.meta).toEqual({ knownAttachments: [] })
    })

    // The point of the snapshot: a foreign change must not move it. Reading the answer at save time
    //   would show *their* set, compare equal to itself and let the delete-all through.
    it('keeps the opened-with attachments even after a foreign change', async () => {
      mockAnswer({
        attachments: [
          {
            __typename: 'StoredFile',
            id: convertToGraphQLId('Store', 1),
            internalId: 1,
            name: 'handbook.pdf',
            size: 1234,
            type: 'application/pdf',
            preferences: {},
          },
        ],
      } as never)

      const view = await visitEditView()

      await view.findByRole('radio', { name: 'Public' })

      // Somebody else removes the file.
      await getKnowledgeBaseAnswerUpdatesSubscriptionHandler().trigger({
        knowledgeBaseAnswerUpdates: {
          answer: {
            id: ANSWER_ID,
            title: TITLE,
            content: {
              __typename: 'KnowledgeBaseAnswerTranslationContent',
              id: CONTENT_ID,
              bodyForEditing: '<p>Some text.</p>',
            },
            visibility: EnumKnowledgeBaseVisibility.Published,
            attachments: [],
            category: { id: CATEGORY_ID, breadcrumb: [{ id: CATEGORY_ID, title: 'Hardware' }] },
          },
        },
      } as never)

      mockKnowledgeBaseAnswerUpdateMutation({
        knowledgeBaseAnswerUpdate: { answer: null, errors: null },
      })

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      // Their change is on screen, so submitting now asks first.
      const dialog = await view.findByRole('dialog', { name: 'Submit your changes' })
      await view.events.click(within(dialog).getByRole('button', { name: 'Submit' }))

      const calls = await waitForKnowledgeBaseAnswerUpdateMutationCalls()
      const variables = calls.at(-1)?.variables as { meta?: Record<string, unknown> }

      expect(variables.meta?.knownAttachments).toEqual([{ name: 'handbook.pdf', size: 1234 }])
    })

    it('submits the answer attributes and the form the files are in', async () => {
      await submitEdit()

      const calls = await waitForKnowledgeBaseAnswerUpdateMutationCalls()
      const variables = calls.at(-1)?.variables as {
        answerId: string
        locale: string
        input: Record<string, unknown>
      }

      expect(variables).toMatchObject({
        answerId: ANSWER_ID,
        locale: LOCALE,
        input: {
          categoryId: CATEGORY_ID,
          title: 'Updated title',
          visibility: EnumKnowledgeBaseVisibility.Published,
        },
      })

      // The files ride along in the upload cache of this form, which the updater seeded with the
      //   answer's own when the tab opened - so handing the id over applies them rather than
      //   wiping them.
      expect(variables.input).toHaveProperty('formId')

      // Never through this mutation: an existing answer is tagged from its sidebar, straight onto
      //   the record, so the update input carries no `tags` at all.
      expect(variables.input).not.toHaveProperty('tags')
    })

    it('notifies on a successful save', async () => {
      const view = await submitEdit()

      expect(
        await view.findByText('Knowledge base answer updated successfully.'),
      ).toBeInTheDocument()
    })

    // What happens once the save went through - the tab belongs to the answer, so unlike the create
    //   view staying is a real option, and the default. The two other options both close the tab and
    //   differ only in where they leave the editor.
    describe('screen behavior', () => {
      const setBehavior = (behavior?: EnumKnowledgeBaseAnswerScreenBehavior) =>
        mockUserCurrent({ preferences: { knowledgeBaseAnswerSecondaryAction: behavior } })

      it('keeps the tab open by default', async () => {
        setBehavior()

        await submitEdit()

        await waitForKnowledgeBaseAnswerUpdateMutationCalls()

        expect(getTestRouter().currentRoute.value.name).toBe('KnowledgeBaseAnswerEdit')

        // Both halves matter: staying means neither navigating nor dropping the tab, and a
        //   regression that only dropped it would keep the route unchanged.
        expect(getGraphQLMockCalls(UserCurrentTaskbarItemDeleteDocument)).toHaveLength(0)
      })

      it('closes the tab and opens the answer', async () => {
        setBehavior(EnumKnowledgeBaseAnswerScreenBehavior.CloseTabAndOpenAnswer)

        await submitEdit()

        await waitFor(() => {
          expect(getTestRouter().currentRoute.value).toMatchObject({
            name: 'KnowledgeBaseAnswer',
            params: { localeCode: LOCALE, answerInternalId: String(ANSWER_INTERNAL_ID) },
          })
        })

        const calls = await waitForUserCurrentTaskbarItemDeleteMutationCalls()

        expect(calls.at(-1)?.variables).toEqual({ id: TASKBAR_ITEM_ID })

        // Replaced, not pushed: the closed tab's URL must not stay behind us in history, where
        //   going back would run the taskbar guard again and recreate the tab just closed.
        expect(String(getTestRouter().options.history.state.back ?? '')).not.toContain('/edit')
      })

      // The category comes from the mutation result rather than from the answer the tab was opened
      //   with, so a save that *moved* the answer leaves for the category it moved to.
      it('closes the tab and opens the category', async () => {
        setBehavior(EnumKnowledgeBaseAnswerScreenBehavior.CloseTabAndOpenCategory)

        await submitEdit()

        await waitFor(() => {
          expect(getTestRouter().currentRoute.value).toMatchObject({
            name: 'KnowledgeBaseCategory',
            params: { localeCode: LOCALE, categoryInternalId: '1' },
          })
        })

        const calls = await waitForUserCurrentTaskbarItemDeleteMutationCalls()

        expect(calls.at(-1)?.variables).toEqual({ id: TASKBAR_ITEM_ID })
      })
    })
  })

  // A locale the knowledge base does not have - a hand-edited URL, or a stale taskbar tab whose
  //   locale was removed since - must not open an edit form that cannot be written.
  // One tab per answer *and* locale, which is what the taskbar key's locale qualifier is for:
  //   switching the language opens the other translation's own tab instead of reusing this one.
  it('opens the other translation when the language is switched', async () => {
    const view = await visitEditView()

    await view.findByDisplayValue(TITLE)

    // The compact header renders the same controls, so target the visible full one.
    await view.events.click(view.getAllByRole('button', { name: 'Change language' }).at(-1)!)
    await view.events.click((await view.findAllByText('Deutsch')).at(-1)!)

    const router = getTestRouter()

    await waitFor(() => {
      expect(router.currentRoute.value.params).toMatchObject({
        localeCode: 'de-de',
        answerInternalId: String(ANSWER_INTERNAL_ID),
      })
    })
  })

  it('does not open the edit view in an unknown locale', async () => {
    const view = await visitEditView('fr-fr')

    expect(
      await view.findByText('This knowledge base is not available in the selected language.'),
    ).toBeInTheDocument()

    expect(view.queryByDisplayValue(TITLE)).not.toBeInTheDocument()
  })

  // Somebody else saving this translation after the tab was opened. The same sentence is used by
  //   the banner and by the confirmation on submit, so being asked says no more than what has been
  //   on screen all along.
  describe('a concurrent change', () => {
    const foreignSave = (overrides: Record<string, unknown> = {}) =>
      getKnowledgeBaseAnswerUpdatesSubscriptionHandler().trigger({
        knowledgeBaseAnswerUpdates: {
          answer: {
            id: ANSWER_ID,
            title: TITLE,
            content: {
              __typename: 'KnowledgeBaseAnswerTranslationContent',
              id: CONTENT_ID,
              bodyForEditing: '<p>Some text.</p>',
            },
            visibility: EnumKnowledgeBaseVisibility.Published,
            attachments: [],
            editedAt: '2026-08-27T10:00:00Z',
            editedBy: {
              __typename: 'User',
              id: convertToGraphQLId('User', 42),
              firstname: 'Second',
              lastname: 'Editor',
              fullname: 'Second Editor',
            },
            category: { id: CATEGORY_ID, breadcrumb: [{ id: CATEGORY_ID, title: 'Hardware' }] },
            ...overrides,
          },
        },
      } as never)

    it('shows nothing until somebody else saves', async () => {
      const view = await visitEditView()

      await view.findByRole('radio', { name: 'Public' })

      expect(view.queryByText(/Submitting will replace/)).not.toBeInTheDocument()
    })

    it('names who changed it', async () => {
      const view = await visitEditView()

      await view.findByRole('radio', { name: 'Public' })

      await foreignSave()

      expect(
        await view.findByText(
          'Second Editor has updated this answer. Submitting will replace their changes.',
        ),
      ).toBeInTheDocument()
    })

    // Their version is one click away, so the editor can read it before deciding what to do with
    //   their own changes. The edit tab stays in the taskbar meanwhile.
    it('links to the stored answer', async () => {
      const view = await visitEditView()

      await view.findByRole('radio', { name: 'Public' })

      await foreignSave()

      const link = await view.findByRole('link', { name: 'View answer' })

      expect(link).toHaveAttribute(
        'href',
        `/desktop/knowledge-base/locale/${LOCALE}/answer/${ANSWER_INTERNAL_ID}`,
      )
    })

    // `editedBy` comes back null for an editor the viewer may not look at
    //   permission, so the warning has to stand without a name rather than not
    //   appear at all.
    it('warns without a name when the editor may not be looked at', async () => {
      const view = await visitEditView()

      await view.findByRole('radio', { name: 'Public' })

      await foreignSave({ editedBy: null })

      expect(
        await view.findByText(
          'This answer has been updated. Submitting will replace those changes.',
        ),
      ).toBeInTheDocument()
    })

    // An attachment change moves no timestamp at all (measured), and it is the one that would
    //   silently delete somebody's file - so it must not be the one that goes unmentioned.
    it('warns about an attachment change, which moves no timestamp', async () => {
      mockAnswer({ attachments: [], editedAt: '2026-08-01T10:00:00Z' } as never)

      const view = await visitEditView()

      await view.findByRole('radio', { name: 'Public' })

      await foreignSave({
        editedAt: '2026-08-01T10:00:00Z',
        attachments: [
          {
            __typename: 'StoredFile',
            id: convertToGraphQLId('Store', 9),
            internalId: 9,
            name: 'theirs.pdf',
            size: 99,
            type: 'application/pdf',
            preferences: {},
          },
        ],
      })

      // Named after nobody on purpose: `editedBy` moves with `editedAt`, and neither moved here,
      //   so the editor it still names is whoever last wrote the title or body - not whoever
      //   attached this file.
      expect(
        await view.findByText(
          'This answer has been updated. Submitting will replace those changes.',
        ),
      ).toBeInTheDocument()
    })

    // The snapshot has to move to what this save stored, or the warning outlives it and starts
    //   accusing this editor of their own change - with every following submit gated behind the
    //   confirmation dialog. The mutation response carries the new `editedAt`, so the tab has
    //   everything it needs to re-baseline itself.
    it('stops warning once this editor saved', async () => {
      // Staying on the tab is the premise: the whole point is what the tab looks like *after* the
      //   save, and the behavior selector is a stored preference other examples in this file set.
      mockUserCurrent({
        preferences: {
          knowledgeBaseAnswerSecondaryAction: EnumKnowledgeBaseAnswerScreenBehavior.StayOnTab,
        },
      })

      mockKnowledgeBaseAnswerUpdateMutation({
        knowledgeBaseAnswerUpdate: {
          answer: {
            id: ANSWER_ID,
            title: TITLE,
            content: {
              __typename: 'KnowledgeBaseAnswerTranslationContent',
              id: CONTENT_ID,
              bodyWithUrls: '<p>Some text.</p>',
            },
            visibility: EnumKnowledgeBaseVisibility.Published,
            translationMissing: false,
            internalAt: null,
            publishedAt: '2026-08-01T10:00:00Z',
            archivedAt: null,
            // Later than the foreign save below, as this one stored last.
            editedAt: '2026-08-27T11:00:00Z',
            editedBy: null,
            tags: [],
            attachments: [],
            category: { id: CATEGORY_ID, breadcrumb: [{ id: CATEGORY_ID, title: 'Hardware' }] },
          },
          errors: null,
        },
      } as never)

      const view = await visitEditView()

      await view.findByRole('radio', { name: 'Public' })

      await foreignSave()

      expect(await view.findByText(/Submitting will replace/)).toBeInTheDocument()

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      const dialog = await view.findByRole('dialog', { name: 'Submit your changes' })
      await view.events.click(within(dialog).getByRole('button', { name: 'Submit' }))

      await waitForKnowledgeBaseAnswerUpdateMutationCalls()

      await waitFor(() => {
        expect(view.queryByText(/Submitting will replace/)).not.toBeInTheDocument()
      })

      // The sharper half: submitting again goes straight through, so the warning is really gone
      //   rather than only its text node.
      await view.events.click(view.getByRole('button', { name: 'Update' }))

      expect(view.queryByRole('dialog', { name: 'Submit your changes' })).not.toBeInTheDocument()
    })

    // A category or a publication state change moves no `editedAt` at all - it is what an editor of
    //   *another locale's* tab does without touching a word of this translation. This form
    //   resubmits both on every save, so an unwarned one would be reverted silently.
    it('warns about a category change, which moves no editedAt', async () => {
      const view = await visitEditView()

      await view.findByRole('radio', { name: 'Public' })

      await foreignSave({
        editedAt: null,
        category: {
          id: convertToGraphQLId('KnowledgeBase::Category', 2),
          breadcrumb: [{ id: convertToGraphQLId('KnowledgeBase::Category', 2), title: 'Software' }],
        },
      })

      // And names nobody, for the same reason as the attachment change above: this save is one
      //   `editedBy` says nothing about, even though the subscription still carries a name.
      expect(
        await view.findByText(
          'This answer has been updated. Submitting will replace those changes.',
        ),
      ).toBeInTheDocument()
    })

    it('warns about a visibility change, which moves no editedAt', async () => {
      const view = await visitEditView()

      await view.findByRole('radio', { name: 'Public' })

      await foreignSave({ editedAt: null, visibility: EnumKnowledgeBaseVisibility.Internal })

      expect(
        await view.findByText(
          'This answer has been updated. Submitting will replace those changes.',
        ),
      ).toBeInTheDocument()
    })

    // Confirming has to *get* the editor there: the backend refuses exactly the save the banner
    //   warned about (ConcurrentAttachmentChange), so without the override the confirmation would
    //   lead nowhere and no save would ever succeed.
    it('overrides the backend guard once the submit is confirmed', async () => {
      const view = await visitEditView()

      await view.findByRole('radio', { name: 'Public' })

      await foreignSave()

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      const dialog = await view.findByRole('dialog', { name: 'Submit your changes' })
      await view.events.click(within(dialog).getByRole('button', { name: 'Submit' }))

      const calls = await waitForKnowledgeBaseAnswerUpdateMutationCalls()
      const variables = calls.at(-1)?.variables as { meta?: Record<string, unknown> }

      expect(variables.meta?.skipValidators).toEqual([
        EnumUserErrorException.ServiceKnowledgeBaseAnswerUpdateValidatorConcurrentAttachmentChangeError,
      ])
    })

    it('does not submit when the confirmation is declined', async () => {
      mockKnowledgeBaseAnswerUpdateMutation({
        knowledgeBaseAnswerUpdate: { answer: null, errors: null },
      })

      const view = await visitEditView()

      await view.findByRole('radio', { name: 'Public' })

      await foreignSave()

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      const dialog = await view.findByRole('dialog', { name: 'Submit your changes' })
      await view.events.click(within(dialog).getByRole('button', { name: 'Cancel & go back' }))

      expect(getGraphQLMockCalls(KnowledgeBaseAnswerUpdateDocument)).toHaveLength(0)
    })
  })

  // The other editors of this translation, in the bottom bar. What this pins is the wiring the
  //   presentational spec cannot: the subscription has to be keyed off the *tab's* key, locale and
  //   all, because that is the string the backend collected the entries under. Keyed off anything
  //   else - or left disabled because the key arrives late - the row simply stays empty, with no
  //   type error to notice it by.
  describe('live users', () => {
    it('subscribes with the tab key and shows the other editors', async () => {
      const view = await visitEditView()

      await view.findByDisplayValue(TITLE)

      const handler = getKnowledgeBaseAnswerLiveUserUpdatesSubscriptionHandler()

      expect(handler).toBeDefined()

      // The tab's own key, locale included - not the answer id, and not a key rebuilt here.
      const calls = await waitForGraphQLMockCalls(KnowledgeBaseAnswerLiveUserUpdatesDocument)

      expect(calls.at(-1)?.variables).toEqual({
        key: `KnowledgeBase__Answer-${ANSWER_INTERNAL_ID}-${LOCALE}`,
        app: EnumTaskbarApp.Desktop,
      })

      await handler.trigger({
        knowledgeBaseAnswerLiveUserUpdates: {
          liveUsers: [
            {
              user: {
                id: convertToGraphQLId('User', 42),
                fullname: 'Second Editor',
                firstname: 'Second',
                lastname: 'Editor',
                vip: false,
                active: true,
                outOfOffice: false,
                image: null,
              },
              apps: [
                {
                  name: EnumTaskbarApp.Desktop,
                  editing: true,
                  lastInteraction: new Date().toISOString(),
                },
              ],
            },
          ],
        },
      })

      expect(await view.findByRole('img', { name: 'Avatar (Second Editor)' })).toBeInTheDocument()
    })
  })
})
