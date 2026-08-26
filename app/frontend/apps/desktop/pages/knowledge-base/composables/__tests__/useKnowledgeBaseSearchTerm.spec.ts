// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { defineComponent } from 'vue'

import renderComponent, {
  getHistory,
  getTestRouter,
} from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { useKnowledgeBaseSearchTerm } from '../useKnowledgeBaseSearchTerm.ts'

// Short enough to keep the suite fast, long enough that `flushPromises` cannot cross it —
//   so "has not committed yet" stays deterministic.
const DEBOUNCE_TIME = 20

// For the cases that must show something happening *without* the debounce, or a pending
//   commit being abandoned: long enough that it cannot have fired.
const NEVER_FIRES = 5000

const ROOT_PATH = '/knowledge-base/locale/en-us'
const CATEGORY_PATH = '/knowledge-base/locale/en-us/category/2'
const OTHER_LOCALE_PATH = '/knowledge-base/locale/de-de'

const routerRoutes = [
  { name: 'Dashboard', path: '/', component: { template: '<div />' } },
  {
    name: 'KnowledgeBaseBrowse',
    path: '/knowledge-base/locale/:localeCode?',
    component: { template: '<div />' },
  },
  {
    name: 'KnowledgeBaseCategory',
    path: '/knowledge-base/locale/:localeCode/category/:categoryInternalId(\\d+)',
    component: { template: '<div />' },
  },
]

let api: ReturnType<typeof useKnowledgeBaseSearchTerm>

const TestComponent = defineComponent({
  props: {
    debounceTime: { type: Number, default: DEBOUNCE_TIME },
  },
  setup(props) {
    api = useKnowledgeBaseSearchTerm(props.debounceTime)
    return () => null
  },
})

const mountComposable = async (url = ROOT_PATH, debounceTime = DEBOUNCE_TIME) => {
  // The field reads the route as it renders, so the URL has to be in place first. The
  //   router only exists once something has rendered, hence the history fallback for the
  //   first test of the file.
  const router = getTestRouter()
  if (router) await router.replace(url)
  else getHistory().replace(url)

  renderComponent(TestComponent, { props: { debounceTime }, router: true, routerRoutes })

  await flushPromises()

  // Forget the navigation that positioned us, so call counts below are about the
  //   composable only.
  vi.mocked(getTestRouter().replace).mockClear()
  vi.mocked(getTestRouter().push).mockClear()

  return api
}

const currentFullPath = () => getTestRouter().currentRoute.value.fullPath

// Long enough for a scheduled commit to have fired, so "it never fired" means something.
const settleDebounce = () =>
  new Promise((resolve) => {
    setTimeout(resolve, DEBOUNCE_TIME * 5)
  })

describe('useKnowledgeBaseSearchTerm', () => {
  it('shows the term the URL arrived with', async () => {
    const { searchTerm, searchQuery } = await mountComposable(`${ROOT_PATH}?query=printer`)

    expect(searchTerm.value).toBe('printer')
    expect(searchQuery.value).toBe('printer')
  })

  it('takes the last of a repeated term rather than showing an array', async () => {
    const { searchTerm } = await mountComposable(`${ROOT_PATH}?query=first&query=second`)

    expect(searchTerm.value).toBe('second')
  })

  it('treats a whitespace-only term in the URL as no term', async () => {
    const { searchTerm, searchQuery } = await mountComposable(`${ROOT_PATH}?query=%20%20`)

    expect(searchTerm.value).toBe('')
    expect(searchQuery.value).toBe('')
  })

  it('commits the typed term to the URL once typing settles', async () => {
    const { searchTerm } = await mountComposable()

    searchTerm.value = 'printer'

    await waitFor(() => expect(currentFullPath()).toBe(`${ROOT_PATH}?query=printer`))
  })

  it('commits only once for a burst of keystrokes', async () => {
    const { searchTerm } = await mountComposable()

    searchTerm.value = 'p'
    searchTerm.value = 'pri'
    searchTerm.value = 'printer'

    await waitFor(() => expect(currentFullPath()).toBe(`${ROOT_PATH}?query=printer`))

    expect(getTestRouter().replace).toHaveBeenCalledTimes(1)
  })

  it('replaces rather than pushes, so keystrokes do not become history entries', async () => {
    const { searchTerm } = await mountComposable()

    searchTerm.value = 'printer'

    await waitFor(() => expect(currentFullPath()).toBe(`${ROOT_PATH}?query=printer`))

    expect(getTestRouter().push).not.toHaveBeenCalled()
  })

  it('drops the term from the URL immediately when the field is emptied', async () => {
    const { searchTerm } = await mountComposable(`${ROOT_PATH}?query=printer`, NEVER_FIRES)

    searchTerm.value = ''

    await flushPromises()

    // No `waitFor`: clearing must not wait out the debounce, or the page would keep
    //   showing results for a term that is no longer in the field.
    expect(currentFullPath()).toBe(ROOT_PATH)
  })

  it('commits a trimmed term, and settles the field on it', async () => {
    const { searchTerm } = await mountComposable()

    searchTerm.value = '  printer  '

    await waitFor(() => expect(currentFullPath()).toBe(`${ROOT_PATH}?query=printer`))

    expect(searchTerm.value).toBe('printer')
  })

  it('searches a picked term at once, without waiting out the debounce', async () => {
    const { searchNow, searchTerm } = await mountComposable(ROOT_PATH, NEVER_FIRES)

    searchNow('publication_state:draft')

    await flushPromises()

    expect(currentFullPath()).toBe(`${ROOT_PATH}?query=publication_state:draft`)
    expect(searchTerm.value).toBe('publication_state:draft')
  })

  // Otherwise a term half typed before picking a suggestion would land on top of it.
  it('abandons a pending typed commit when a term is picked', async () => {
    const { searchTerm, searchNow } = await mountComposable()

    searchTerm.value = 'printer'
    searchNow('publication_state:draft')

    await settleDebounce()

    expect(currentFullPath()).toBe(`${ROOT_PATH}?query=publication_state:draft`)
    expect(getTestRouter().replace).toHaveBeenCalledTimes(1)
  })

  it('keeps unrelated query parameters', async () => {
    const { searchTerm } = await mountComposable(`${ROOT_PATH}?keep=me`)

    searchTerm.value = 'printer'

    await waitFor(() => expect(currentFullPath()).toBe(`${ROOT_PATH}?keep=me&query=printer`))
  })

  it('leaves the URL alone when typing lands back on the committed term', async () => {
    const { searchTerm } = await mountComposable(`${ROOT_PATH}?query=printer`)

    searchTerm.value = 'printers'
    searchTerm.value = 'printer'

    await settleDebounce()

    expect(getTestRouter().replace).not.toHaveBeenCalled()
  })

  it('leaves the URL alone when navigating away from a pending commit', async () => {
    const { searchTerm } = await mountComposable()

    searchTerm.value = 'printer'

    await getTestRouter().push(CATEGORY_PATH)
    await settleDebounce()

    expect(getTestRouter().replace).not.toHaveBeenCalled()
    expect(currentFullPath()).toBe(CATEGORY_PATH)
  })

  it('lets a URL that moved without us win over what is being typed', async () => {
    const { searchTerm } = await mountComposable(`${ROOT_PATH}?query=printer`, NEVER_FIRES)

    searchTerm.value = 'printer jam'

    // What a back/forward, or following a link carrying `?query=`, arrives as.
    await getTestRouter().replace(`${ROOT_PATH}?query=scanner`)
    await flushPromises()

    expect(searchTerm.value).toBe('scanner')
  })

  it('does not carry a search into another category', async () => {
    const { searchTerm } = await mountComposable(`${ROOT_PATH}?query=printer`)

    await getTestRouter().push(CATEGORY_PATH)
    await flushPromises()

    expect(searchTerm.value).toBe('')
    expect(currentFullPath()).toBe(CATEGORY_PATH)
  })

  // Another category or locale is another scope ("Search within %s"), so a term that never
  //   made it into the URL must not follow along — nor may its pending commit land there.
  it.each([
    ['another category is opened', CATEGORY_PATH],
    ['the locale is switched', OTHER_LOCALE_PATH],
  ])('abandons a term still being typed when %s', async (_, path) => {
    const { searchTerm } = await mountComposable(ROOT_PATH, NEVER_FIRES)

    searchTerm.value = 'printer'

    await getTestRouter().push(path)
    await flushPromises()

    expect(searchTerm.value).toBe('')
    expect(currentFullPath()).toBe(path)
  })
})
