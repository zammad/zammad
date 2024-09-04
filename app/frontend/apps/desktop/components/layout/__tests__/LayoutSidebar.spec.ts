// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { fireEvent } from '@testing-library/vue'
import { beforeEach, describe, expect } from 'vitest'

import renderComponent, {
  type ExtendedRenderResult,
} from '#tests/support/components/renderComponent.ts'

import LayoutSidebar from '#desktop/components/layout/LayoutSidebar.vue'

import { SidebarPosition } from '../types.ts'

describe('LayoutSidebar', () => {
  describe('Feature: Collapsible', () => {
    let view: ExtendedRenderResult

    beforeEach(() => {
      view = renderComponent(LayoutSidebar, {
        props: {
          name: 'testBar-collapsible',
          id: 'sidebar-test',
          collapsible: true,
          resizable: false,
        },
      })
    })

    it('shows CollapseButton in expanded state when collapsible is true', async () => {
      expect(view.queryByLabelText('Expand sidebar')).not.toBeInTheDocument()

      // By default, is expanded and aria label shows collapse action
      expect(view.queryByLabelText('Collapse sidebar')).toBeInTheDocument()
    })

    it('does not show CollapseButton when collapsible is false', async () => {
      await view.rerender({ collapsible: false })

      expect(
        view.queryByLabelText('collapse this item'),
      ).not.toBeInTheDocument()

      expect(view.queryByLabelText('expand this item')).not.toBeInTheDocument()
    })

    it('hides action Button when no iconCollapsed is provided', async () => {
      expect(view.queryByTestId('action-button')).not.toBeInTheDocument()
    })

    it('shows an action Button when iconCollapsed is provided and sidebar is collapsed', async () => {
      await view.rerender({ iconCollapsed: 'person-gear' })
      const collapseButton = await view.findByLabelText('Collapse sidebar')
      await view.events.click(collapseButton)
      expect(view.queryByTestId('action-button')).toBeInTheDocument()
    })
  })

  describe('Feature: Resizable', () => {
    let view: ExtendedRenderResult

    beforeEach(() => {
      view = renderComponent(LayoutSidebar, {
        props: {
          name: 'testBar-resize',
          id: 'sidebar-test',
          collapsible: false,
          resizable: true,
        },
      })
    })

    it('shows ResizeLine when resizable is true', async () => {
      expect(view.queryByLabelText('Resize sidebar')).toBeInTheDocument()
    })

    it('does not show ResizeLine when resizable is false', async () => {
      await view.rerender({ resizable: false })

      expect(view.queryByLabelText('Resize sidebar')).not.toBeInTheDocument()
    })

    it('resizes sidebar when ResizeLine is clicked and dragged', async () => {
      const resizeLine = await view.findByLabelText('Resize sidebar')

      await view.events.click(resizeLine)

      // Emulate mouse down on resize handle and mouse move on document
      await fireEvent.mouseDown(resizeLine, { clientX: 0 })
      await fireEvent.mouseMove(document, { clientX: 100 })
      await fireEvent.mouseUp(document, { clientX: 100 })

      expect(view.emitted('resize-horizontal')).toEqual([[100]])
    })

    it('resizes sidebar when ResizeLine is touched and dragged', async () => {
      const resizeLine = await view.findByLabelText('Resize sidebar')

      await view.events.click(resizeLine)

      // Touch device
      await fireEvent.touchStart(resizeLine, { pageX: 0 })
      await fireEvent.touchMove(document, { pageX: 100 })
      await fireEvent.touchEnd(document, { pageX: 100 })

      // :TODO check why we can not use toEqual([[100]])
      expect(view.emitted('resize-horizontal')).toBeTruthy()
    })

    it('resets width when ResizeLine is double clicked', async () => {
      const resizeLine = await view.findByLabelText('Resize sidebar')

      await fireEvent.dblClick(resizeLine)

      expect(view.emitted('reset-width')).toBeTruthy()
    })
  })

  describe('Feature: Position', () => {
    let view: ExtendedRenderResult

    beforeEach(() => {
      view = renderComponent(LayoutSidebar, {
        props: {
          name: 'testBar-position',
          id: 'sidebar-test',
          collapsible: true,
          resizable: true,
        },
      })
    })

    it('defaults to start position (left)', async () => {
      const aside = view.getByRole('complementary')

      expect(aside).toHaveClass('border-e')

      const collapseButton = view.getByLabelText('Collapse sidebar')

      expect(collapseButton.parentElement).toHaveClasses([
        'focus-within:opacity-100',
        'hover:opacity-100',
      ])

      const resizeLine = view.getByLabelText('Resize sidebar')

      expect(resizeLine.parentElement).toHaveClasses([
        'ltr:right-0',
        'ltr:translate-x-1/2',
        'rtl:left-0',
        'rtl:-translate-x-1/2',
      ])
    })

    it('supports end position (right)', async () => {
      await view.rerender({ position: SidebarPosition.End })

      const aside = view.getByRole('complementary')

      expect(aside).toHaveClass('border-s')

      const resizeLine = view.getByLabelText('Resize sidebar')

      expect(resizeLine.parentElement).toHaveClasses([
        'ltr:left-0',
        'rtl:right-0',
        'ltr:-translate-x-1/2',
        'rtl:right-0',
        'rtl:translate-x-1/2',
      ])
    })
  })
})
