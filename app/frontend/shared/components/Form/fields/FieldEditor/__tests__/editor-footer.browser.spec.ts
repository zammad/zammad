// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { findEditor, mountEditor } from './browser-utils.ts'

describe('displays footer information', () => {
  it("doesn't display footer by default", async () => {
    await mountEditor()
    await findEditor()

    await expect.element(page.getByTestId('editor-footer')).not.toBeInTheDocument()
  })

  it("doesn't display footer, if footer if disabled", async () => {
    await mountEditor({
      contentType: 'text/plain',
      meta: {
        footer: {
          disabled: true,
          text: '/AB',
        },
      },
    })

    // doesn't exist before async editor initialization
    expect(page.getByTestId('editor-footer').query()).toBeNull()
    expect(page.getByText('/AB').query()).toBeNull()

    // doesn't exist after async editor initialization
    await findEditor()

    expect(page.getByTestId('editor-footer').query()).toBeNull()
    expect(page.getByText('/AB').query()).toBeNull()
  })

  it('displays footer, if footer text is provided', async () => {
    await mountEditor({
      contentType: 'text/plain',
      meta: {
        footer: {
          text: '/AB',
        },
      },
    })

    // exists before async editor initialization
    await expect.element(page.getByTestId('editor-footer')).toBeInTheDocument()
    await expect.element(page.getByText('/AB')).toBeInTheDocument()

    // exists after async editor initialization
    await findEditor()

    await expect.element(page.getByTestId('editor-footer')).toBeInTheDocument()
    await expect.element(page.getByText('/AB')).toBeInTheDocument()
  })

  it('does allow input below limit', async () => {
    await mountEditor({
      contentType: 'text/plain',
      meta: {
        footer: {
          text: '/AB',
          maxlength: 10,
          warningLength: 5,
          allowExceedMaxLength: true,
        },
      },
    })

    const availableCharacters = page.getByTitle('Available characters')

    await expect.element(page.getByTestId('editor-footer')).toBeInTheDocument()
    await expect.element(page.getByText('/AB')).toBeInTheDocument()
    await expect.element(availableCharacters).toHaveTextContent('10')

    const editor = await findEditor()

    await expect.element(page.getByTestId('editor-footer')).toBeInTheDocument()
    await expect.element(page.getByText('/AB')).toBeInTheDocument()
    await expect.element(availableCharacters).toHaveTextContent('10')

    await userEvent.type(editor, '123456789')

    await expect.element(availableCharacters).toHaveTextContent('1')
    await expect.element(availableCharacters).toHaveClass('text-orange')

    await userEvent.type(editor, '{Enter}{Enter}{Enter}4567')

    await expect.element(availableCharacters).toHaveTextContent('-6')
    await expect.element(availableCharacters).toHaveClass('text-red')
  })

  it('prevents input bellow limit', async () => {
    await mountEditor({
      contentType: 'text/plain',
      meta: {
        footer: {
          text: '/AB',
          maxlength: 10,
          warningLength: 5,
          allowExceedMaxLength: false,
        },
      },
    })

    const editor = await findEditor()

    await userEvent.type(editor, '123456789')
    await userEvent.type(editor, '{Enter}{Enter}{Enter}4567')

    await expect.element(page.getByTitle('Available characters')).toHaveTextContent('0')
  })
})
