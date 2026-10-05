// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import UserDetailTopBar from '#desktop/pages/user/components/UserDetailTopBar.vue'

// jsdom has no layout and never scrolls, so the top bar measures 0 everywhere. Drive its inputs
// instead: both headers report `measuredHeight`, the title line of the compact header ends
// `titleLineBottom` below its top edge, and `scrollY` stands in for the scroll position of the
// content container.
const measuredHeight = ref(0)
const titleLineBottom = ref(0)
const scrollY = ref(0)

vi.mock('@vueuse/core', async (importOriginal) => {
  const modules = await importOriginal<typeof import('@vueuse/core')>()

  return {
    ...modules,
    useElementSize: () => ({ width: ref(0), height: measuredHeight }),
    useScroll: () => ({ y: scrollY, directions: {} }),
  }
})

vi.mock('#desktop/composables/useOffsetBottomWithin.ts', () => ({
  useOffsetBottomWithin: () => titleLineBottom,
}))

vi.mock('#desktop/pages/user/components/UserDetailTopBar/useTopBarHeader.ts', () => ({
  useTopBarHeader: () => ({
    copyUserDisplayNameToClipboard: vi.fn(),
    allowedTopLevelActions: ref([]),
    secondLevelActions: ref([]),
  }),
}))

const user = generateObjectData('User', {
  id: convertToGraphQLId('User', 2),
  internalId: 2,
  firstname: 'Nicole',
  lastname: 'Braun',
  fullname: 'Nicole Braun',
})

const renderUserDetailTopBar = () =>
  renderComponent(UserDetailTopBar, {
    props: { user, userDisplayName: 'Nicole Braun', contentContainerElement: null },
    router: true,
  })

// jsdom has no `inert` property, so Vue renders the binding as a plain attribute value.
const expectInert = (header: HTMLElement, inert: boolean) => {
  expect(header).toHaveAttribute('inert', String(inert))
}

describe('UserDetailTopBar', () => {
  // Both headers are 100px high, so the compact header would only dock past 70px of scrolling
  // (100px minus the head start of 30px).
  beforeEach(() => {
    measuredHeight.value = 100
    titleLineBottom.value = 40
    scrollY.value = 0
  })

  it('keeps the full header interactive while the compact title line is out of view', async () => {
    const view = renderUserDetailTopBar()

    scrollY.value = 20
    await waitForNextTick()

    const compactHeader = view.getByTestId('user-detail-top-bar-clipped-details')

    expectInert(compactHeader, true)
    expect(compactHeader).toHaveStyle({ transform: 'translateY(-50px)' })
    expectInert(view.getByTestId('user-detail-top-bar-full-details'), false)
  })

  it('lets the compact header take over as soon as any of its title line is in view', async () => {
    const view = renderUserDetailTopBar()

    scrollY.value = 60
    await waitForNextTick()

    const compactHeader = view.getByTestId('user-detail-top-bar-clipped-details')

    expectInert(compactHeader, false)
    expect(compactHeader, 'still sliding in').toHaveStyle({ transform: 'translateY(-10px)' })
    expectInert(view.getByTestId('user-detail-top-bar-full-details'), true)
  })
})
