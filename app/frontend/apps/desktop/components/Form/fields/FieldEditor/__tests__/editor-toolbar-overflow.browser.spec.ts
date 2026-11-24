// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page } from 'vitest/browser'

import {
  findEditor,
  mountEditor,
} from '#shared/components/Form/fields/FieldEditor/__tests__/browser-utils.ts'

const mountToolbar = async (width: number) => {
  const { container } = await mountEditor()

  container.style.width = `${width}px`

  await findEditor()

  return container
}

const toolbar = () => page.getByRole('toolbar')
const insertTableButton = () => toolbar().getByRole('button', { name: 'Insert table', exact: true })
const overflowMenuButton = () =>
  toolbar().getByRole('button', { name: 'Overflow menu', exact: true })

const overflowMenuInDom = () =>
  page.getByRole('button', { name: 'Overflow menu', exact: true, includeHidden: true }).query()

// The width the toolbar leaves next to its last action, measured while all actions fit.
const spareWidth = () => {
  const actionBar = toolbar().element()
  const buttons = actionBar.firstElementChild!.querySelectorAll('button')
  const lastAction = buttons[buttons.length - 1]

  return actionBar.getBoundingClientRect().right - lastAction.getBoundingClientRect().right
}

// A toolbar shown again before it noticed it was hidden would not have been out of view.
const hide = async (container: HTMLElement) => {
  container.hidden = true

  await expect.poll(overflowMenuInDom).toBeNull()
}

describe('editor toolbar overflow menu', () => {
  it('runs an action that does not fit the toolbar from the overflow menu', async () => {
    await mountToolbar(400)

    await expect.element(insertTableButton()).toBeDisabled()

    await overflowMenuButton().click()
    await page.getByRole('menuitem', { name: 'Insert table' }).click()

    await expect.element(page.getByRole('textbox').getByRole('table')).toBeVisible()
  })

  it('drops the overflow menu once a toolbar shown again has room for all actions', async () => {
    const container = await mountToolbar(1200)

    await expect.element(insertTableButton()).toBeEnabled()

    // Wide enough for all actions, but not for the overflow menu next to them.
    const fittingWidth = 1200 - spareWidth() + 10

    container.style.width = '400px'
    await expect.element(overflowMenuButton()).toBeVisible()

    await hide(container)

    container.style.width = `${fittingWidth}px`
    container.hidden = false

    await expect.element(insertTableButton()).toBeEnabled()
    await expect.element(overflowMenuButton()).not.toBeInTheDocument()
  })

  it('shows the overflow menu again when a toolbar shown again is still too narrow', async () => {
    const container = await mountToolbar(400)

    await expect.element(overflowMenuButton()).toBeVisible()

    await hide(container)

    container.hidden = false

    await expect.element(overflowMenuButton()).toBeVisible()
    await expect.element(insertTableButton()).toBeDisabled()
  })
})
