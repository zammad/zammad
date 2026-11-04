// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { findEditor, mountEditor } from './browser-utils.ts'

const typeOrderedList = async () => {
  await mountEditor()

  const editor = await findEditor()
  await editor.click()
  await page.getByTestId('action-bar').getByLabelText('Add ordered list').click()

  await userEvent.keyboard('First{Enter}Middle{Enter}Third{Enter}Last')

  return editor
}

// Turns the ordered list off for the item the cursor sits on, breaking the list in two.
const turnListOffFor = async (item: string) => {
  await page.getByRole('textbox').getByText(item).click()
  await page.getByTestId('action-bar').getByLabelText('Add ordered list').click()
}

describe('editor ordered list numbering', () => {
  it('continues the numbering when the list is broken apart', async () => {
    const editor = await typeOrderedList()

    await turnListOffFor('Third')

    // "First" and "Middle" keep 1 and 2, "Third" is no longer numbered, so "Last" becomes 3.
    const lists = editor.getByRole('list')

    await expect.element(lists).toHaveLength(2)
    await expect.element(lists.last()).toHaveAttribute('start', '3')
    await expect.element(lists.first()).not.toHaveAttribute('start')
  })

  it('restarts the numbering when the list is turned on again', async () => {
    const editor = await typeOrderedList()
    const lists = editor.getByRole('list')

    await turnListOffFor('Third')
    await expect.element(lists.last()).toHaveAttribute('start', '3')

    // Turning the list off and on again asks for a fresh count.
    await turnListOffFor('Last')
    await expect.element(lists).toHaveLength(1)

    await editor.getByText('Last').click()
    await page.getByTestId('action-bar').getByLabelText('Add ordered list').click()

    await expect.element(lists).toHaveLength(2)
    await expect.element(lists.last()).not.toHaveAttribute('start')
  })
})
