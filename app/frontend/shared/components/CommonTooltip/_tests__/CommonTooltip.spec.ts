// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { h } from 'vue'

import renderComponent, {
  type ExtendedRenderResult,
} from '#tests/support/components/renderComponent.ts'

import CommonTooltipVue, { type Props } from '../CommonTooltip.vue'

const CustomComponent = (props: any) => {
  return props.state
    ? h('div', { 'data-test-id': 'customTooltip' }, 'tooltip')
    : null
}
CustomComponent.props = ['id', 'messages', 'heading', 'state']

const renderTooltip = (type: 'popup' | 'inline', props: Props) => {
  return renderComponent(CommonTooltipVue, {
    props,
    slots: {
      default: '<span data-test-id="trigger">T</span>',
    },
    visuals: {
      objectAttributes: {} as any,
      tooltip: {
        type,
        component: CustomComponent,
      },
    },
  })
}

type Context = { view: ExtendedRenderResult }

describe('rendering "inline" tooltip', async () => {
  const test = it<Context>

  beforeEach<Context>((context) => {
    context.view = renderTooltip('inline', { name: 'inline' })
  })

  test('renders tooltip when mousing over', async ({ view }) => {
    await view.events.hover(view.getByTestId('trigger'))
    expect(view.getByTestId('customTooltip')).toBeInTheDocument()
    await view.events.keyboard('{Escape}')
    expect(view.queryByTestId('customTooltip')).not.toBeInTheDocument()
  })

  test('renders tooltip when focusing', async ({ view }) => {
    view.getByTestId('tooltipTrigger').focus()
    await flushPromises()
    expect(await view.findByTestId('customTooltip')).toBeInTheDocument()
    await view.events.keyboard('{Escape}')
    expect(view.queryByTestId('customTooltip')).not.toBeInTheDocument()
  })
})

describe('rendering "popup" tooltip', () => {
  const test = it<Context>

  beforeEach<Context>((context) => {
    context.view = renderTooltip('popup', { name: 'inline' })
  })

  test("doesn't render popup when mousing over", async ({ view }) => {
    await view.events.hover(view.getByTestId('trigger'))
    expect(view.queryByTestId('customTooltip')).not.toBeInTheDocument()
  })

  test("doesn't render popup when focusing", async ({ view }) => {
    view.getByTestId('tooltipTrigger').focus()
    await flushPromises()
    expect(view.queryByTestId('customTooltip')).not.toBeInTheDocument()
  })

  test('renders when clicked on a button', async ({ view }) => {
    await view.events.click(view.getByTestId('trigger'))
    expect(view.getByTestId('customTooltip')).toBeInTheDocument()
    await view.events.keyboard('{Escape}')
    expect(view.queryByTestId('customTooltip')).not.toBeInTheDocument()
  })
})
