// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { type ExtendedRenderResult } from '#tests/support/components/index.ts'
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
  EnumFormUpdaterId,
  EnumKnowledgeBaseAnswerScreenBehavior,
  EnumKnowledgeBaseVisibility,
  EnumTaskbarEntity,
  EnumTaskbarEntityAccess,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import getUuid from '#shared/utils/getUuid.ts'

import {
  mockKnowledgeBaseAnswerAddMutation,
  waitForKnowledgeBaseAnswerAddMutationCalls,
} from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseAnswerAdd.mocks.ts'
import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import {
  mockKnowledgeBaseCategorySubcategoriesQuery,
  waitForKnowledgeBaseCategorySubcategoriesQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'
import { waitForUserCurrentTaskbarItemDeleteMutationCalls } from '#desktop/entities/user/current/graphql/mutations/userCurrentTaskbarItemDelete.mocks.ts'
import { mockUserCurrentTaskbarItemListQuery } from '#desktop/entities/user/current/graphql/queries/userCurrentTaskbarItemList.mocks.ts'

const mockKnowledgeBase = () =>
  mockKnowledgeBaseQuery({
    knowledgeBase: {
      id: convertToGraphQLId('KnowledgeBase', 1),
      translation: { title: 'My Knowledge Base' },
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
//   waits for the taskbar entry of the route's entity key.
const TASKBAR_ITEM_ID = convertToGraphQLId('Taskbar', 1)

const mockTaskbarTab = (tabId: string) =>
  mockUserCurrentTaskbarItemListQuery({
    userCurrentTaskbarItemList: [
      {
        __typename: 'UserTaskbarItem',
        id: TASKBAR_ITEM_ID,
        key: `KnowledgeBaseAnswerCreateScreen-${tabId}`,
        callback: EnumTaskbarEntity.KnowledgeBaseAnswerCreate,
        entityAccess: EnumTaskbarEntityAccess.Granted,
        entity: null,
      },
    ],
  })

const CATEGORY_OPTIONS = [
  { value: 1, label: 'Hardware' },
  { value: 2, label: 'Software' },
]

// What the real updater answers with: the category options and their `required` on every round
//   trip (FormUpdater::Updater::KnowledgeBase::Answer::Concerns::HasCategoryField), the initial
//   values only on the first one (FormUpdater::Concerns::ProvidesInitialValues) - so a state the
//   user picks afterwards is not overwritten by the next answer. Without a seeded category it
//   answers like a draft opened from the toolbar, where the editor picks one first.
const mockAnswerCreateFormUpdater = ({ seededCategoryId = 1 } = {}) =>
  mockFormUpdaterQuery(({ meta }) => ({
    formUpdater: {
      fields: {
        categoryId: {
          options: CATEGORY_OPTIONS,
          required: true,
          ...(meta.initial && seededCategoryId ? { value: seededCategoryId } : {}),
        },
        ...(meta.initial ? { visibility: { value: EnumKnowledgeBaseVisibility.Draft } } : {}),
      },
    },
  }))

const visitCreateView = async (tabId = getUuid(), locale = 'en-us', query = '') => {
  mockTaskbarTab(tabId)

  return visitView(`/knowledge-base/locale/${locale}/answer/create/${tabId}${query}`)
}

// A path of its own per category, so the header's breadcrumb tells which one it renders.
const mockCategoryPaths = () =>
  mockKnowledgeBaseCategorySubcategoriesQuery(({ categoryId }) => {
    const id = categoryId ? String(categoryId) : undefined

    return {
      knowledgeBaseCategorySubcategories: {
        category: id
          ? {
              id,
              breadcrumb: [
                {
                  id,
                  translation: {
                    title: CATEGORY_OPTIONS.find(
                      (option) => option.value === getIdFromGraphQLId(id),
                    )?.label,
                  },
                },
              ],
            }
          : null,
        subcategories: [],
      },
    }
  })

const pickCategory = async (view: ExtendedRenderResult, label: string) => {
  await view.events.click(view.getByLabelText('Category'))

  // The tree select selects on the option's inner control, not on the option itself.
  const option = await view.findByRole('option', { name: label })

  await view.events.click(option.firstChild as Element)
}

describe('knowledge base answer create', () => {
  beforeEach(() => {
    mockApplicationConfig({ kb_active: true })
    mockPermissions(['knowledge_base.editor'])
    mockKnowledgeBase()
  })

  // The content column per the design: title, the editor, an attachment area and tags.
  it('renders the content fields', async () => {
    const view = await visitCreateView()

    expect(await view.findByLabelText('Title')).toBeInTheDocument()
    expect(view.getByLabelText('Text')).toBeInTheDocument()
    expect(view.getByText('Attach files')).toBeInTheDocument()
    expect(view.getByLabelText('Tags')).toBeInTheDocument()
  })

  it('renders the title field, with the breadcrumb as the heading', async () => {
    const view = await visitCreateView()

    expect(await view.findByLabelText('Title')).toBeInTheDocument()

    // Both headers render the breadcrumb; its last item is the page heading.
    expect(
      await view.findAllByRole('heading', { name: 'New knowledge base answer' }),
      'an untitled draft falls back to a static heading',
    ).not.toHaveLength(0)
  })

  // The field is declared once (useAnswerFormSchema.ts) and teleported into the header - proof it
  //   actually lands there, rather than in the content column it used to render in.
  // Same column as the fields below it, like in the edit view - see its spec for what this
  //   looked like when the header capped it at the browse view's wider measure instead.
  it('lines the header title field up with the form column', async () => {
    const view = await visitCreateView()

    expect((await view.findByLabelText('Title')).closest('.max-w-270')).not.toBeNull()
    expect(view.getByLabelText('Text').closest('.max-w-270')).not.toBeNull()
  })

  it('renders the title field inside the header, not the content column', async () => {
    const view = await visitCreateView()

    const header = view.getByTestId('knowledge-base-header-full')

    expect(header).toContainElement(await view.findByLabelText('Title'))
  })

  // The header must be on screen from the first render, because the title field is teleported into
  //   it and a Teleport resolves its target exactly once. A header that skeletons - which unmounts
  //   the target - while the form comes up leaves the draft with no title field at all, for good.
  //   So the category path must never gate it: here the query returns none for the seeded category.
  it('renders the title field while the seeded category has no path yet', async () => {
    mockKnowledgeBaseCategorySubcategoriesQuery(() => ({
      knowledgeBaseCategorySubcategories: { category: null, subcategories: [] },
    }))

    const view = await visitCreateView(getUuid(), 'en-us', '?categoryId=42')

    const header = view.getByTestId('knowledge-base-header-full')

    expect(header).toContainElement(await view.findByLabelText('Title'))
  })

  // The taskbar id is what makes the auto-save work: without it the backend stores no draft, and
  //   nothing about the rendered form would look wrong.
  it('tells the form updater which taskbar to store the draft in', async () => {
    await visitCreateView()

    const calls = await waitForFormUpdaterQueryCalls()

    expect(calls.at(-1)?.variables).toMatchObject({
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterKnowledgeBaseAnswerCreate,
      meta: {
        additionalData: {
          taskbarId: TASKBAR_ITEM_ID,
        },
      },
    })
  })

  // The draft is one answer translation: its category options have to read in the language the
  //   answer is written in, not in the editor's profile language.
  it('tells the form updater which locale the draft is written in', async () => {
    await visitCreateView(getUuid(), 'de-de')

    const calls = await waitForFormUpdaterQueryCalls()

    expect(calls.at(-1)?.variables).toMatchObject({
      meta: { additionalData: { locale: 'de-de' } },
    })
  })

  // The seed lives only in the URL until something stores it, and the taskbar link does not carry
  //   it - so the draft has to persist itself once, or reopening the tab loses its category.
  // A draft whose category the editor may not write to (any more): the updater clears it, and the
  //   header must not fall back to the seed - its query would come back Forbidden and take the
  //   whole view to a not-found page, leaving no way to reopen the draft and move it.
  it('drops a seeded category the form does not confirm', async () => {
    mockFormUpdaterQuery({
      formUpdater: { fields: { categoryId: { options: [], required: true } } },
    })

    await visitCreateView(getUuid(), 'en-us', '?categoryId=42')

    await waitForFormUpdaterQueryCalls()

    const calls = await waitForKnowledgeBaseCategorySubcategoriesQueryCalls()

    await waitFor(() => {
      expect(calls.at(-1)?.variables.categoryId).toBeFalsy()
    })
  })

  // Opened from a category, that category is preselected - the updater resolves the seed.
  it('forwards the category the draft was opened for', async () => {
    await visitCreateView(getUuid(), 'en-us', '?categoryId=42')

    const calls = await waitForFormUpdaterQueryCalls()

    expect(calls.at(-1)?.variables).toMatchObject({
      meta: {
        additionalData: {
          categoryId: '42',
        },
      },
    })
  })

  // A locale the knowledge base does not have - a hand-edited URL, or a stale taskbar tab whose
  //   locale was removed since - must not open a draft that cannot be written.
  it('does not open a draft in an unknown locale', async () => {
    const view = await visitCreateView(getUuid(), 'fr-fr')

    expect(
      await view.findByText('This knowledge base is not available in the selected language.'),
    ).toBeInTheDocument()

    expect(view.queryByLabelText('Title')).not.toBeInTheDocument()
  })

  // Nothing is stored for the heading to read here, so it follows the form - the opposite of the
  //   edit view, whose breadcrumb stays on the stored answer while a new title is typed.
  it('updates the breadcrumb heading while the title is typed', async () => {
    const view = await visitCreateView()

    await view.events.type(await view.findByLabelText('Title'), 'How to reset a password')

    await waitFor(() => {
      expect(view.getAllByRole('heading', { name: 'How to reset a password' })).not.toHaveLength(0)
    })

    expect(
      view.queryByRole('heading', { name: 'New knowledge base answer' }),
      'the static fallback is only for a draft with no title yet',
    ).not.toBeInTheDocument()
  })

  // The breadcrumb is this view's heading, and the category it names comes from a form field.
  //   Unlike in the browse view - which opens a category from its parent's listing, so its path
  //   travels along in the cache - a category picked here was never browsed, and fetching its path
  //   must not take the header off the screen and leave a skeleton in its place.
  it('keeps the header up while the path of another category loads', async () => {
    mockAnswerCreateFormUpdater()
    mockCategoryPaths()

    const view = await visitCreateView()

    await waitFor(() => {
      expect(view.getByTestId('knowledge-base-header-full')).toHaveTextContent('Hardware')
    })

    const header = view.getByTestId('knowledge-base-header-full')

    await pickCategory(view, 'Software')

    await waitFor(() => {
      // This very element, not one rendered in its place: a skeleton in between would have
      //   replaced it, which is what the flash was.
      expect(header).toBeInTheDocument()
      expect(header).toHaveTextContent('Software')
    })
  })

  // The other half of it: the path itself. A switch must not blank the category out of the
  //   breadcrumb either - the heading would jump twice, once for the round trip and once back.
  //   The moment between picking a category and its path arriving cannot be observed against a
  //   mock that answers synchronously, so a category the query has no path for stands in for it.
  it('keeps the path it has until the picked category has one', async () => {
    mockAnswerCreateFormUpdater()

    const hardwareId = convertToGraphQLId('KnowledgeBase::Category', 1)

    mockKnowledgeBaseCategorySubcategoriesQuery(({ categoryId }) => ({
      knowledgeBaseCategorySubcategories: {
        category:
          categoryId === hardwareId
            ? {
                id: hardwareId,
                breadcrumb: [{ id: hardwareId, translation: { title: 'Hardware' } }],
              }
            : null,
        subcategories: [],
      },
    }))

    const view = await visitCreateView()

    await waitFor(() => {
      expect(view.getByTestId('knowledge-base-header-full')).toHaveTextContent('Hardware')
    })

    await pickCategory(view, 'Software')

    const calls = await waitForKnowledgeBaseCategorySubcategoriesQueryCalls()

    await waitFor(() => {
      expect(calls.at(-1)?.variables.categoryId).toBe(
        convertToGraphQLId('KnowledgeBase::Category', 2),
      )
    })

    expect(view.getByTestId('knowledge-base-header-full')).toHaveTextContent('Hardware')
  })

  // The same for the first pick, where there is no path on screen to hold on to: a draft opened
  //   without a category has a header all the same, and it stays for that round trip too.
  it('keeps the header up while the path of the first picked category loads', async () => {
    mockAnswerCreateFormUpdater({ seededCategoryId: 0 })
    mockCategoryPaths()

    const view = await visitCreateView()

    // The sidebar fields come with the first round trip, and the category is picked in there.
    await view.findByRole('radio', { name: 'Draft' })

    const header = view.getByTestId('knowledge-base-header-full')

    await pickCategory(view, 'Hardware')

    await waitFor(() => {
      expect(header).toBeInTheDocument()
      expect(header).toHaveTextContent('Hardware')
    })
  })

  // Everything the browse header offers acts on a stored node, which a draft is not.
  it('offers neither a public link nor an action menu', async () => {
    const view = await visitCreateView()

    await view.findAllByRole('heading', { name: 'New knowledge base answer' })

    expect(view.queryByRole('link', { name: 'View public knowledge base' })).not.toBeInTheDocument()
    expect(view.queryByRole('button', { name: 'Additional actions' })).not.toBeInTheDocument()
  })

  it('mints a tab id when the URL carries none', async () => {
    await visitView('/knowledge-base/locale/en-us/answer/create')

    const router = getTestRouter()

    await waitFor(() => {
      expect(router.currentRoute.value.params.tabId).toBeTruthy()
    })
  })

  it('opens another draft when the language is switched', async () => {
    const tabId = getUuid()
    const view = await visitCreateView(tabId)

    await view.findAllByRole('heading', { name: 'New knowledge base answer' })

    // The compact header renders the same controls, so target the visible full one.
    await view.events.click(view.getAllByRole('button', { name: 'Change language' }).at(-1)!)
    await view.events.click((await view.findAllByText('Deutsch')).at(-1)!)

    const router = getTestRouter()

    await waitFor(() => {
      expect(router.currentRoute.value.params.localeCode).toBe('de-de')
    })

    expect(
      router.currentRoute.value.params.tabId,
      'a draft is one translation, so the other locale is a draft of its own',
    ).not.toBe(tabId)
  })

  // The sidebar half of the design. The fields are part of the *same* form as the content column
  //   and only teleported out of it, so one form id keeps carrying the draft and its uploads.
  describe('sidebar', () => {
    beforeEach(() => {
      mockAnswerCreateFormUpdater()
    })

    it('renders the visibility and category fields inside the sidebar', async () => {
      const view = await visitCreateView()

      const sidebar = await view.findByRole('complementary', { name: 'Content sidebar' })

      // The reader's title and icon, so switching between creating and reading an answer does not
      //   move the sidebar around.
      expect(view.getByRole('heading', { name: 'Knowledge base answer' })).toBeInTheDocument()

      // Like the bottom bar, the sidebar body waits for the first form updater round trip.
      await view.findByRole('radio', { name: 'Draft' })

      expect(sidebar, 'the fields are teleported out of the content column').toContainElement(
        view.getByLabelText('Visibility'),
      )
      expect(sidebar).toContainElement(view.getByLabelText('Category'))

      // The per-option notes the design asks for, reusing the strings of the legacy form.
      expect(view.getByText('Only visible to editors')).toBeInTheDocument()
      expect(view.getByText('Visible to readers & editors')).toBeInTheDocument()
      expect(view.getByText('Visible to everyone')).toBeInTheDocument()
    })

    // The 2026-08-28 clarification: the create form shows the visibility, and nothing about
    //   scheduling one for later - no timing field, and no scheduled-visibility widget either,
    //   both of which need an answer to schedule for.
    it('offers the state but no way to schedule one', async () => {
      const view = await visitCreateView()

      await view.findByRole('radio', { name: 'Draft' })

      expect(view.getByLabelText('Visibility')).toBeInTheDocument()

      expect(view.queryByLabelText('Timing')).not.toBeInTheDocument()
      expect(view.queryByText('Scheduled visibility')).not.toBeInTheDocument()
      expect(
        view.queryByRole('button', { name: 'Add scheduled visibility' }),
      ).not.toBeInTheDocument()
    })

    // Per the 2026-08-26 header decision: unlike the edit header's badges, which come from the
    //   stored answer and never change, a draft has no stored state - so this one has to be live.
    it('shows the visibility badge live, since a draft has no stored answer to read instead', async () => {
      const view = await visitCreateView()

      const header = view.getByTestId('knowledge-base-header-full')

      expect(await within(header).findByText('Draft')).toBeInTheDocument()

      await view.events.click(await view.findByRole('radio', { name: 'Internal' }))

      expect(await within(header).findByText('Internal')).toBeInTheDocument()
      expect(within(header).queryByText('Draft')).not.toBeInTheDocument()
    })

    // The reason the fields are teleported instead of living in a form of their own: one form id
    //   is what carries the draft, its auto-save and its upload cache. A second form in the
    //   sidebar would render the same fields and pass every other example here.
    it('keeps the sidebar fields in the form that carries the draft', async () => {
      const view = await visitCreateView()

      await view.findByRole('radio', { name: 'Draft' })

      const initialCall = (await waitForFormUpdaterQueryCalls()).at(0)

      await view.events.click(view.getByRole('radio', { name: 'Internal' }))

      await waitFor(async () => {
        const calls = await waitForFormUpdaterQueryCalls()

        expect(calls.at(-1)?.variables.meta).toMatchObject({
          changedField: { name: 'visibility' },
          formId: initialCall?.variables.meta.formId,
          additionalData: { taskbarId: TASKBAR_ITEM_ID },
        })
      })
    })

    it('offers the categories the updater resolved, required and not clearable', async () => {
      const view = await visitCreateView()

      await view.findByRole('radio', { name: 'Draft' })

      const category = view.getByLabelText('Category')

      expect(category.closest('.formkit-outer')).toHaveAttribute('data-required')

      // The seed the updater resolved, which also makes the check below meaningful: a clearable
      //   field offers its clear button only while it holds a value.
      await waitFor(() => {
        expect(category).toHaveTextContent('Hardware')
      })

      expect(
        view.queryByRole('button', { name: 'Clear selection' }),
        'an answer always belongs to a category, there is no top level to fall back on',
      ).not.toBeInTheDocument()

      await view.events.click(category)

      expect(await view.findByRole('option', { name: 'Hardware' })).toBeInTheDocument()
      expect(view.getByRole('option', { name: 'Software' })).toBeInTheDocument()
    })
  })

  // The submit path: what the mutation is handed, and what happens to the tab afterwards.
  describe('creating the answer', () => {
    const ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 42)
    const TITLE = 'How to reset a password'

    // Pinned, so a choice made by an earlier example cannot decide where these ones end up.
    beforeEach(() => {
      mockUserCurrent({ preferences: {} })
    })

    // @param visibility state to pick before submitting, `undefined` to leave it on `draft`
    const submitDraft = async (options: { visibility?: string; tabId?: string } = {}) => {
      const tabId = options.tabId ?? getUuid()

      mockAnswerCreateFormUpdater()
      mockKnowledgeBaseAnswerAddMutation({
        knowledgeBaseAnswerAdd: {
          answer: {
            id: ANSWER_ID,
            visibility: EnumKnowledgeBaseVisibility.Draft,
            position: 1,
            translation: {
              id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
              title: TITLE,
            },
            category: { id: convertToGraphQLId('KnowledgeBase::Category', 1) },
          },
          errors: null,
        },
      })

      const view = await visitCreateView(tabId)

      // Both are required, so the form does not submit without them; the category comes seeded
      //   from the updater.
      await view.events.type(await view.findByLabelText('Title'), TITLE)
      await view.events.type(view.getByRole('textbox', { name: 'Text' }), 'Open the settings.')

      if (options.visibility) {
        await view.events.click(await view.findByRole('radio', { name: options.visibility }))
      }

      await view.events.click(view.getByRole('button', { name: 'Create' }))

      return view
    }

    it('submits the draft as a new answer', async () => {
      await submitDraft()

      const calls = await waitForKnowledgeBaseAnswerAddMutationCalls()
      const variables = calls.at(-1)?.variables as {
        locale: string
        input: {
          categoryId: string
          title: string
          visibility: string
          formId?: string
        }
      }

      expect(variables).toMatchObject({
        // The locale of the draft, from its own URL - not whatever the store last browsed.
        locale: 'en-us',
        input: {
          // The field works with internal ids, the input takes a GraphQL one.
          categoryId: convertToGraphQLId('KnowledgeBase::Category', 1),
          title: TITLE,
          visibility: EnumKnowledgeBaseVisibility.Draft,
        },
      })

      // The files live in the upload cache of this form, so its id is what hands them over.
      expect(variables.input.formId).toBeTruthy()
    })

    // The state alone, with no date to go with it: it applies as soon as the answer is created.
    it('sends the picked state as the visibility', async () => {
      await submitDraft({ visibility: 'Public' })

      const calls = await waitForKnowledgeBaseAnswerAddMutationCalls()

      expect(calls.at(-1)?.variables).toMatchObject({
        input: { visibility: EnumKnowledgeBaseVisibility.Published },
      })
    })

    // The story's acceptance criteria ask for the edit view's control here as well - one choice,
    //   one stored preference, whichever of the two views the answer was written in.
    describe('screen behavior', () => {
      // The create screen's own key, never the edit one - they are configured independently.
      const setBehavior = (behavior?: EnumKnowledgeBaseAnswerScreenBehavior) =>
        mockUserCurrent({ preferences: { knowledgeBaseAnswerCreateSecondaryAction: behavior } })

      // The control itself - what it offers and what it stores - is covered by its own spec; this
      //   is about the Add answer view carrying it at all, which is what the criteria ask for. Its
      //   default is what this view did before it had a choice: leave for the answer it filed.
      it('renders the control in the bottom bar', async () => {
        setBehavior()
        mockAnswerCreateFormUpdater()

        const view = await visitCreateView()

        expect(
          await view.findByRole('button', { name: 'Close tab and open the answer' }),
        ).toBeInTheDocument()
      })

      // Adding another answer: this tab is done, and a fresh form opens in the category the answer
      //   was filed in. A tab of its own, which is what gets the next answer a clean form id - and
      //   with it an upload cache that does not still hold the files just handed over.
      it('closes the tab and opens a fresh form in the same category', async () => {
        setBehavior(EnumKnowledgeBaseAnswerScreenBehavior.CloseTabAndAddAnother)

        const tabId = getUuid()

        await submitDraft({ tabId })

        await waitFor(() => {
          expect(getTestRouter().currentRoute.value).toMatchObject({
            name: 'KnowledgeBaseAnswerCreate',
            params: { localeCode: 'en-us' },
            // The internal id, which is what the form's own category field works with.
            query: { categoryId: '1' },
          })
        })

        expect(getTestRouter().currentRoute.value.params.tabId).not.toBe(tabId)

        const calls = await waitForUserCurrentTaskbarItemDeleteMutationCalls()

        expect(calls.at(-1)?.variables).toEqual({ id: TASKBAR_ITEM_ID })
      })

      // Only after the answer exists - a failed create has to keep the draft. Also what an editor
      //   who never touched the control gets.
      it('closes the tab and opens the created answer', async () => {
        setBehavior(EnumKnowledgeBaseAnswerScreenBehavior.CloseTabAndOpenAnswer)

        await submitDraft()

        await waitFor(() => {
          expect(getTestRouter().currentRoute.value).toMatchObject({
            name: 'KnowledgeBaseAnswer',
            params: { localeCode: 'en-us', answerInternalId: '42' },
          })
        })

        const calls = await waitForUserCurrentTaskbarItemDeleteMutationCalls()

        expect(calls.at(-1)?.variables).toEqual({ id: TASKBAR_ITEM_ID })
      })

      // The edit screen's own value, which this one does not offer - a leftover or a hand-edited
      //   preference must not leave the create view without a behavior at all.
      it('falls back to its default for a behavior it does not offer', async () => {
        setBehavior(EnumKnowledgeBaseAnswerScreenBehavior.StayOnTab)

        await submitDraft()

        await waitFor(() => {
          expect(getTestRouter().currentRoute.value).toMatchObject({
            name: 'KnowledgeBaseAnswer',
            params: { localeCode: 'en-us', answerInternalId: '42' },
          })
        })
      })

      // The category comes from the mutation result rather than from the form, so it is the one
      //   the answer really landed in.
      it('closes the tab and opens the category', async () => {
        setBehavior(EnumKnowledgeBaseAnswerScreenBehavior.CloseTabAndOpenCategory)

        await submitDraft()

        await waitFor(() => {
          expect(getTestRouter().currentRoute.value).toMatchObject({
            name: 'KnowledgeBaseCategory',
            params: { localeCode: 'en-us', categoryInternalId: '1' },
          })
        })

        const calls = await waitForUserCurrentTaskbarItemDeleteMutationCalls()

        expect(calls.at(-1)?.variables).toEqual({ id: TASKBAR_ITEM_ID })
      })
    })
  })
})
