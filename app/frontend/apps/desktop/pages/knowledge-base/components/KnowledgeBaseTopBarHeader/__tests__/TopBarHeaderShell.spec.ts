// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { getAlertClasses } from '#shared/initializer/initializeAlertClasses.ts'

import TopBarHeaderShell from '../TopBarHeaderShell.vue'

// jsdom has no layout and never scrolls, so the shell measures 0 everywhere. Drive its
//   inputs instead: both header wrappers report `measuredHeight`, the content column
//   `measuredWidth`, and `scrollY` stands in for the container's scroll position. The
//   defaults leave the page at the top with the compact header undocked.
const measuredWidth = ref(0)
const measuredHeight = ref(0)
const scrollY = ref(0)

vi.mock('@vueuse/core', async (importOriginal) => {
  const modules = await importOriginal<typeof import('@vueuse/core')>()

  return {
    ...modules,
    useElementSize: () => ({ width: measuredWidth, height: measuredHeight }),
    useScroll: () => ({ y: scrollY, directions: {} }),
  }
})

// Scrolled past the point where the compact header takes over from the full one.
const scrollPastFullHeader = () => {
  measuredHeight.value = 100
  scrollY.value = 500
}

const renderShell = (props = {}) =>
  renderComponent(TopBarHeaderShell, {
    props: {
      contentContainerElement: null,
      ...props,
    },
    slots: {
      compact: '<div data-test-id="compact-slot">compact</div>',
      full: '<div data-test-id="full-slot">full</div>',
      skeleton: '<div data-test-id="skeleton-slot">skeleton</div>',
    },
    router: true,
  })

describe('TopBarHeaderShell', () => {
  beforeEach(() => {
    measuredWidth.value = 0
    measuredHeight.value = 0
    scrollY.value = 0
  })

  it('renders both headers so the compact one can slide in on scroll', () => {
    const view = renderShell()

    expect(view.getByTestId('full-slot')).toBeInTheDocument()
    expect(view.getByTestId('compact-slot')).toBeInTheDocument()
    expect(view.queryByTestId('skeleton-slot')).not.toBeInTheDocument()
  })

  it('replaces both headers with the skeleton while loading', async () => {
    const view = renderShell({ loading: true })

    // CommonLoader debounces the skeleton, so it only appears after a moment.
    expect(await view.findByTestId('skeleton-slot')).toBeInTheDocument()
    expect(view.queryByTestId('full-slot')).not.toBeInTheDocument()
    expect(
      view.queryByTestId('compact-slot'),
      'no stale compact header behind the skeleton',
    ).not.toBeInTheDocument()
  })

  it('docks no alert without a message', () => {
    const view = renderShell()

    expect(view.queryAllByRole('alert')).toHaveLength(0)
  })

  it('docks the alert below the full and the compact header alike', () => {
    const view = renderShell({ alertMessage: 'No translation available for this locale' })

    // One per header, so the message stays visible across the scroll swap.
    expect(view.getAllByText('No translation available for this locale')).toHaveLength(2)
  })

  it('tints the docked alert translucently over the blurred content', () => {
    const view = renderShell({ alertMessage: 'No translation available for this locale' })

    // The tint comes from the translucent variant on the alert's wrapper, so that the blur is not
    //   faded along with it - as it would be with an `opacity` on the alert itself.
    view.getAllByTestId('knowledge-base-header-alert-background').forEach((background) => {
      expect(background).toHaveClass(getAlertClasses().translucent!.warning)
      expect(background).toHaveClass('backdrop-blur-2xs')
    })

    view.getAllByRole('alert').forEach((alert) => {
      expect(alert).toHaveClass('bg-transparent!')
    })
  })

  it('withholds the alert while loading, when there is nothing settled to warn about', () => {
    const view = renderShell({
      loading: true,
      alertMessage: 'No translation available for this locale',
    })

    expect(view.queryByText('No translation available for this locale')).not.toBeInTheDocument()
  })

  it('exposes only the full header to interaction while at the top of the page', () => {
    const view = renderShell()

    expect(view.getByTestId('knowledge-base-header-compact')).toBeInTheDocument()
    expect(view.getByTestId('knowledge-base-header-full')).toBeInTheDocument()
    expect(view.getByTestId('knowledge-base-header-full')).not.toHaveClass('invisible')
  })

  // The compact header's background is translucent, so anything left of the full
  //   header — most visibly its docked alert — would show through it.
  it('hides the full header once the compact one has taken over', async () => {
    const view = renderShell({ alertMessage: 'No translation available for this locale' })

    scrollPastFullHeader()
    await view.rerender({})

    expect(view.getByTestId('knowledge-base-header-full')).toHaveClass('invisible')
  })

  it('slides the full header entirely out of view, alert included', async () => {
    const view = renderShell({ alertMessage: 'No translation available for this locale' })

    scrollPastFullHeader()
    await view.rerender({})

    // Offset by its own full height, so no strip of it is left below the viewport top.
    expect(view.getByTestId('knowledge-base-header-full')).toHaveStyle({ top: '-100px' })
  })

  // The compact header is absolutely positioned and its containing block spans the
  //   content sidebar too, so without an explicit width it reaches over it.
  it('pins the compact header to the measured content column', () => {
    measuredWidth.value = 960

    const view = renderShell()

    expect(view.getByTestId('knowledge-base-header-compact')).toHaveStyle({ width: '960px' })
  })

  it('leaves the compact header unconstrained until the column has been measured', () => {
    const view = renderShell()

    expect(view.getByTestId('knowledge-base-header-compact')).toHaveStyle({ width: 'auto' })
  })

  it('caps the docked alert at the wide content width by default', () => {
    const view = renderShell({ alertMessage: 'No translation available for this locale' })

    expect(
      view.container.querySelector('.max-w-\\[calc\\(var\\(--container-7xl\\)-2\\.750rem\\)\\]'),
    ).toBeInTheDocument()
  })

  it('caps the docked alert at the article reading width when asked for it', () => {
    const view = renderShell({
      alertMessage: 'No translation available for this locale',
      contentWidth: 'reading',
    })

    // Breaks out of the header's own px-5.5 first, so the reapplied px-5.5 is
    //   the header's own padding, not stacked on top of it.
    expect(
      view.container.querySelector(
        '.-mx-5\\.5.max-w-\\[calc\\(var\\(--container-3xl\\)\\+2\\.750rem\\)\\].px-5\\.5',
      ),
    ).toBeInTheDocument()
  })
})
