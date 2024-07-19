// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import { beforeAll } from 'vitest'
import { h } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import LayoutContent, {
  type Props,
} from '#desktop/components/layout/LayoutContent.vue'

const breadcrumbItems = [
  {
    label: 'Test Profile',
    route: '/test-profile',
  },
  {
    label: 'Test Foo',
    route: '/test-foo',
  },
]

const renderLayoutContent = (
  slots: typeof LayoutContent.slots,
  props?: Props,
) => {
  return renderComponent(LayoutContent, {
    props: {
      ...props,
      breadcrumbItems: props?.breadcrumbItems || breadcrumbItems,
    },
    slots,
    dialog: true,
    router: true,
  })
}

describe('LayoutContent', () => {
  beforeAll(() => {
    const app = document.createElement('div')
    app.id = 'app'
    document.body.appendChild(app)
  })

  afterAll(() => {
    document.body.innerHTML = ''
  })

  it('renders component with default slot content', () => {
    const wrapper = renderLayoutContent({ default: () => 'Hello Test World!' })

    expect(wrapper.getByText('Hello Test World!')).toBeInTheDocument()
    expect(
      wrapper.getByRole('link', { name: 'Test Profile' }),
    ).toBeInTheDocument()
    expect(wrapper.getByRole('link', { name: 'Test Foo' })).toBeInTheDocument()
  })

  it('renders namespaced content', () => {
    const wrapper = renderLayoutContent({
      default: () => 'Hello Test World!',
      headerRight: () => 'Hello Content Right',
      helpPage: () => 'Hello Help Text',
    })

    expect(wrapper.getByText('Hello Test World!')).toBeInTheDocument()
    expect(wrapper.getByText('Hello Content Right')).toBeInTheDocument()

    expect(wrapper.queryByText('Hello Help Text')).not.toBeInTheDocument() // should not show help text in main content area
  })

  it('shows helpText and hide helpText button if hideDefault prop is true', () => {
    const wrapper = renderLayoutContent(
      {
        default: () => 'Hello Test World!',
        helpPage: () => 'Hello Help Text',
      },
      { showInlineHelp: true, breadcrumbItems },
    )

    expect(wrapper.queryByText('Hello Test World!')).not.toBeInTheDocument() // should not show default content
    expect(
      wrapper.queryByRole('button', { name: 'Help' }),
    ).not.toBeInTheDocument()

    expect(wrapper.getByText('Hello Help Text')).toBeInTheDocument()
  })

  it('shows help dialog with multiple paragraphs', async () => {
    const wrapper = renderLayoutContent(
      {
        default: () => 'Hello Test World!',
      },
      { breadcrumbItems, helpText: ['Hello Test World!', 'Hello Test Foo!'] },
    )

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Help' }))

    expect(await wrapper.findByText('Hello Test World!')).toBeInTheDocument()
    expect(await wrapper.findByText('Hello Test Foo!')).toBeInTheDocument()
  })

  it('shows help dialog with single paragraph', async () => {
    const wrapper = renderLayoutContent(
      {
        default: () => 'Hello Default Slot Content!',
      },
      { breadcrumbItems, helpText: 'Hello Test Text World!' },
    )

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Help' }))

    expect(
      await wrapper.findByText('Hello Test Text World!'),
    ).toBeInTheDocument()
  })

  it('shows custom help text component', async () => {
    const wrapper = renderLayoutContent(
      {
        default: () => 'Hello Test World!',
        helpPage: () => h('h1', 'Hello custom Help Text'),
      },
      { breadcrumbItems },
    )

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Help' }))

    expect(
      await wrapper.findByText('Hello custom Help Text'),
    ).toBeInTheDocument()
  })

  it('allows custom widths', async () => {
    const wrapper = renderLayoutContent(
      {
        default: () => 'Hello Test World!',
      },
      { breadcrumbItems, width: 'narrow' },
    )

    expect(wrapper.getByTestId('layout-wrapper')).toHaveStyle({
      maxWidth: '600px',
    })
  })
})
