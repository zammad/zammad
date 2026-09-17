// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

const RouterViewComponent = {
  template: '<RouterView />',
}

const renderRoutedView = () => renderComponent(RouterViewComponent, { router: true })

// jsdom runs a queued traversal one task after the one that queued it, so a single tick is not
//   enough to observe it.
const flushHistoryTraversal = async () => {
  await new Promise((resolve) => {
    setTimeout(resolve, 0)
  })
  await new Promise((resolve) => {
    setTimeout(resolve, 0)
  })
}

// These two tests only work as a pair and in this order: the first one leaves a traversal queued,
//   the second one proves that it cannot reach across the test boundary.
describe('pending history traversals', () => {
  it('leaves a traversal queued when a test ends right after `router.back()`', async () => {
    const view = renderRoutedView()

    // The first navigation replaces the initial entry, so it takes two to get a history to go back in.
    await view.router.push('/')
    await view.router.push('/example')
    expect(view.getByText('This is a example page.')).toBeInTheDocument()

    // Not awaited on purpose — the test ends before jsdom runs the traversal.
    view.router.back()
  })

  it('keeps the route of the next test active', async () => {
    const view = renderRoutedView()

    await view.router.push('/search/test')

    await flushHistoryTraversal()

    expect(view.router.currentRoute.value.path).toBe('/search/test')
    expect(view.getByText('search')).toBeInTheDocument()
  })
})
