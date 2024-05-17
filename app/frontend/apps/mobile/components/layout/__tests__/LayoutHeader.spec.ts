// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { expect } from 'vitest'

import { renderComponent } from '#tests/support/components/index.ts'

import { i18n } from '#shared/i18n.ts'

import LayoutHeader from '../LayoutHeader.vue'

describe('mobile app header', () => {
  it("doesn't render, if not specified", () => {
    const view = renderComponent(LayoutHeader, { router: true })

    expect(view.queryByTestId('appHeader')).not.toBeInTheDocument()
  })

  describe('title prop tests', () => {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    let view: ReturnType<typeof renderComponent>

    beforeEach(() => {
      view = renderComponent(LayoutHeader, {
        props: { title: 'Test' },
        router: true,
      })
    })
    it('renders translated title, if specified', async () => {
      expect(view.getByTestId('appHeader')).toBeInTheDocument()
      expect(view.getByText('Test')).toBeInTheDocument()

      i18n.setTranslationMap(new Map([['Test2', 'Translated']]))
      await view.rerender({ title: 'Test2' })
      expect(view.getByText('Translated')).toBeInTheDocument()
    })
    it('should be by default a h1', () => {
      expect(view.getByRole('heading', { level: 1 })).toBeInTheDocument()
    })
    it('can add custom class to title', async () => {
      await view.rerender({
        title: 'Test',
        titleClass: 'test-class',
      })
      expect(view.getByText('Test')).toHaveClass('test-class')
    })
  })

  it('renders back button, if specified', async () => {
    const view = renderComponent(LayoutHeader, {
      props: {
        backUrl: '/foo',
        backTitle: 'Back',
      },
      router: true,
    })

    const backButton = view.getByText('Back')

    expect(backButton).toBeInTheDocument()

    i18n.setTranslationMap(new Map([['Test2', 'Translated']]))

    await view.rerender({ backTitle: 'Test2', backUrl: '/bar' })

    expect(view.getByText('Translated')).toBeInTheDocument()
  })

  it('renders action, if specified', async () => {
    const onAction = vi.fn()

    const view = renderComponent(LayoutHeader, {
      props: {
        onAction,
        actionTitle: 'Action',
      },
      router: true,
    })

    const actionButton = view.getByText('Action')

    expect(actionButton).toBeInTheDocument()

    await view.events.click(actionButton)

    expect(onAction).toHaveBeenCalled()

    i18n.setTranslationMap(new Map([['Test2', 'Translated']]))

    await view.rerender({ actionTitle: 'Test2', onAction })

    expect(view.getByText('Translated')).toBeInTheDocument()
  })

  it('hides action, if specified', async () => {
    const onAction = vi.fn()

    const view = renderComponent(LayoutHeader, {
      props: {
        onAction,
        actionTitle: 'Action',
        actionHidden: true,
      },
      router: true,
    })

    expect(view.queryByText('Action')).not.toBeInTheDocument()
  })

  describe('slots test', () => {
    it('display all slots', () => {
      const view = renderComponent(LayoutHeader, {
        slots: {
          before: `<span>Step 1</span>`,
          default: `<h2>Test Heading</h2>`,
          after: `Action`,
        },
        router: true,
      })
      expect(view.getByText('Step 1')).toBeInTheDocument()
      expect(view.getByRole('heading', { level: 2 })).toBeInTheDocument()
      expect(view.getByText('Action')).toBeInTheDocument()
    })
    it('shows fallback if partial slots are used', () => {
      const view = renderComponent(LayoutHeader, {
        title: 'Test',
        slots: {
          before: `<span>Step 1</span>`,
          after: `Action`,
        },
        router: true,
      })
      expect(view.getByText('Step 1')).toBeInTheDocument()
      expect(view.getByRole('heading', { level: 1 })).toBeInTheDocument()
      expect(view.getByText('Action')).toBeInTheDocument()
    })
  })
})
