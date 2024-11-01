// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { useSessionStore } from '#shared/stores/session.ts'

import CommonSectionCollapse, { type Props } from '../CommonSectionCollapse.vue'

const html = String.raw

const renderCommonSectionCollapse = (props: Partial<Props> = {}) => {
  return renderComponent(CommonSectionCollapse, {
    props: {
      id: 'test-id',
      title: 'foobar',
      ...props,
    },
    slots: {
      default: html` <template #default="{ headerId }">
        <nav :aria-labelledby="headerId" />
      </template>`,
    },
    store: true,
  })
}

describe('CommonSectionCollapse', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('toggles content on heading click', async () => {
    const view = renderCommonSectionCollapse()

    expect(view.getByRole('navigation')).toBeInTheDocument()

    const header = view.getByRole('banner')

    const heading = within(header).getByRole('heading', { level: 3 })

    expect(heading).toHaveTextContent('foobar')

    await view.events.click(heading)

    expect(view.queryByRole('navigation')).not.toBeInTheDocument()
  })

  it('toggles content on button click', async () => {
    const view = renderCommonSectionCollapse()

    expect(view.getByRole('navigation')).toBeInTheDocument()

    const header = view.getByRole('banner')

    const button = within(header).getByRole('button')

    await view.events.click(button)

    expect(view.queryByRole('navigation')).not.toBeInTheDocument()
  })

  it('restores collapsed state initially', () => {
    const { userId } = useSessionStore()

    localStorage.setItem(`${userId}-test-id-section-collapsed`, 'true')

    const view = renderCommonSectionCollapse()

    expect(view.queryByRole('navigation')).not.toBeInTheDocument()
  })

  it('provides a11y text to the default slot', () => {
    const view = renderCommonSectionCollapse({
      title: 'a11y',
    })

    expect(view.getByRole('navigation', { name: 'a11y' })).toBeInTheDocument()
  })

  it('supports no collapse (title only) mode', async () => {
    const view = renderCommonSectionCollapse({
      noCollapse: true,
    })

    expect(view.getByRole('navigation')).toBeInTheDocument()

    const header = view.getByRole('banner')

    const heading = within(header).getByRole('heading', { level: 3 })

    expect(heading).toHaveTextContent('foobar')
    expect(within(header).queryByRole('button')).not.toBeInTheDocument()

    await view.events.click(heading)

    expect(view.getByRole('navigation')).toBeInTheDocument()
  })

  it('supports hiding the header', async () => {
    const view = renderCommonSectionCollapse({
      noHeader: true,
    })

    expect(view.getByRole('navigation')).toBeInTheDocument()
    expect(view.queryByRole('banner')).not.toBeInTheDocument()
  })

  it('supports scrollable content mode', async () => {
    const view = renderCommonSectionCollapse({
      scrollable: true,
    })

    const header = view.getByRole('banner')

    expect(header.parentElement).toHaveClass('overflow-y-auto')

    const nav = view.getByRole('navigation')

    expect(nav.parentElement).toHaveClass('overflow-y-auto')

    await view.rerender({
      scrollable: false,
    })

    expect(header.parentElement).not.toHaveClass('overflow-y-auto')
    expect(nav.parentElement).not.toHaveClass('overflow-y-auto')
  })
})
