// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { afterEach, describe, expect, it, vi } from 'vitest'
import { page, userEvent, type Locator } from 'vitest/browser'

import { mockApolloClient, routeRequest } from '#tests/browser/utils.ts'

import {
  EDITOR_IMAGE,
  editorElements,
  editorHtml,
  findEditor,
  mockImageUpload,
  mountEditor,
  selectText,
} from './browser-utils.ts'

const selectAll = () => userEvent.keyboard('{ControlOrMeta>}a{/ControlOrMeta}')

// `userEvent.type` would focus the element, which loses the input for one inside the editor.
//   The keys go to the focused editor instead, where the cursor already sits.
const typeInto = async (element: Locator, text: string) => {
  await expect.element(element).toBeInTheDocument()
  await userEvent.keyboard(text)
}

const testAction = (
  action: string,
  submenu?: string,
  role = 'textbox',
  typeText = 'Something',
  hint = ' ',
) => {
  describe(`testing action - ${action}`, () => {
    it(`${action}${hint} - enabled, text after is affected`, async () => {
      await mountEditor()

      const editor = await findEditor()
      await editor.click()

      if (submenu) {
        await page.getByLabelText(submenu).click()
        await page.getByLabelText(action).click()
      } else {
        await page.getByTestId('action-bar').getByLabelText(action).click()
      }

      await typeInto(page.getByRole(role), typeText)

      await expect.poll(editorHtml).toContain(typeText)
    })

    it(`${action}${hint} - toggle text`, async () => {
      await mountEditor()

      const editor = await findEditor()
      await userEvent.type(editor, typeText)
      await selectAll()

      if (submenu) {
        await page.getByLabelText(submenu).click()
        await page.getByLabelText(action).click()
      } else {
        await page.getByTestId('action-bar').getByLabelText(action).click()
      }

      await expect.poll(editorHtml).toContain(typeText)
    })
  })
}

// The action bar keeps its own popup in the DOM, only an opened one is visible.
const OPEN_POPUP = '[data-test-id="popupWindow"][aria-hidden="false"]'

const findOpenPopup = async () => {
  await expect.poll(() => document.querySelector(OPEN_POPUP)).toBeTruthy()

  return page.elementLocator(document.querySelector(OPEN_POPUP)!)
}

const insertTable = async () => {
  await mountEditor()

  const editor = await findEditor()
  await editor.click()
  await page.getByTestId('action-bar').getByLabelText('Insert table').click()

  await expect.element(page.getByRole('table')).toBeInTheDocument()
}

const testTableAction = (
  actionLabel: string,
  { trCount, tdCount, thCount }: { trCount: number; tdCount: number; thCount?: number },
) => {
  it(`table action - ${actionLabel}`, async () => {
    await insertTable()

    await page.elementLocator(editorElements('td')[0]).click()
    await page.getByRole('button', { name: 'Table options' }).click()

    const popup = await findOpenPopup()

    if (actionLabel === 'Merge cells' || actionLabel === 'Split cells') {
      // Not testable since we would have to select two cells.
      // Nothing to test here.
      return
    }

    await popup.getByLabelText(actionLabel).click()

    await expect.poll(() => editorElements('td').length).toBe(tdCount)
    await expect.poll(() => editorElements('tr').length).toBe(trCount)

    if (thCount) await expect.poll(() => editorElements('th').length).toBe(thCount)
  })
}

describe('testing actions', () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  testAction('Format as underlined')
  testAction('Format as bold')
  testAction('Format as italic')
  testAction('Format as strikethrough')
  testAction('Heading 1', 'Add heading', 'heading')
  testAction('Heading 2', 'Add heading', 'heading')
  testAction('Heading 3', 'Add heading', 'heading')
  testAction('Format as quoted text')
  testAction('Add ordered list', undefined, 'listitem')
  testAction('Add bullet list', undefined, 'listitem')

  testAction('Add ordered list', undefined, 'listitem', 'Something1', ' (multiline)')
  testAction('Add bullet list', undefined, 'listitem', 'Something1', ' (multiline)')

  describe('testing action - remove formatting', () => {
    it('removes formatting', async () => {
      await mountEditor()

      const editor = await findEditor()
      await editor.click()
      await page.getByTestId('action-bar').getByLabelText('Format as bold').click()
      await typeInto(page.getByRole('paragraph'), 'Text')

      await expect.poll(editorHtml).toContain('<p dir="auto"><strong>Text</strong></p>')

      await selectAll()
      await page.getByTestId('action-bar').getByLabelText('Remove formatting').click()

      await expect.poll(editorHtml).toContain('<p dir="auto">Text</p>')
    })
  })

  it('adds a link', async () => {
    vi.spyOn(window, 'prompt').mockReturnValue('https://example.com')

    await mountEditor()

    const editor = await findEditor()
    await editor.click()
    await page.getByTestId('action-bar').getByLabelText('Add link').click()

    const link = editor.getByRole('link')

    await expect.element(link).toHaveAttribute('href', 'https://example.com')
    await expect.element(link).toHaveTextContent('https://example.com')
  })

  it('makes text into a link', async () => {
    vi.spyOn(window, 'prompt').mockReturnValue('https://example.com')

    await mountEditor()

    const editor = await findEditor()
    await editor.click()
    await userEvent.type(editor, 'Text')
    await selectAll()
    await page.getByTestId('action-bar').getByLabelText('Add link').click()

    const link = editor.getByRole('link')

    await expect.element(link).toHaveAttribute('href', 'https://example.com')
    await expect.element(link).toHaveTextContent('Text')
  })

  it('inline image', async () => {
    mockImageUpload(mockApolloClient(), 2062)

    await routeRequest('**/api/v1/attachments/2062', {
      fixture: 'example.png',
      contentType: 'image/png',
    })

    await mountEditor()

    const editor = await findEditor()
    await editor.click()
    await page.getByTestId('action-bar').getByLabelText('Add image').click()

    await userEvent.upload(
      page.getByTestId('editor-image-input'),
      new File(['some image'], 'file.png', { type: 'image/png', lastModified: Date.now() }),
    )

    await expect
      .poll(() => editorElements(EDITOR_IMAGE)[0]?.getAttribute('src'))
      .toBe('/api/v1/attachments/2062')
  })

  describe('table', () => {
    it('inserts a table', async () => {
      await insertTable()

      const table = page.getByRole('table')

      expect(table.element().children).toHaveLength(2)

      await page.elementLocator(editorElements('td')[0]).click()
      await userEvent.keyboard('Table text')

      await expect.element(page.getByText('Table text')).toBeInTheDocument()

      expect(editorElements('tr')).toHaveLength(3)
    })

    describe('actions', () => {
      testTableAction('Insert row above', { trCount: 4, tdCount: 9 })
      testTableAction('Insert row below', { trCount: 4, tdCount: 9 })
      testTableAction('Delete row', { trCount: 2, tdCount: 3 })
      testTableAction('Insert column before', { trCount: 3, tdCount: 8 })
      testTableAction('Insert column after', { trCount: 3, tdCount: 8 })
      testTableAction('Delete column', { trCount: 3, tdCount: 4 })

      testTableAction('Merge cells', { trCount: 3, tdCount: 6, thCount: 2 })
      testTableAction('Split cells', { trCount: 3, tdCount: 6, thCount: 2 })

      testTableAction('Toggle header row', { trCount: 3, tdCount: 9 })
      testTableAction('Toggle header column', {
        trCount: 3,
        tdCount: 4,
        thCount: 5,
      })
      testTableAction('Toggle header cell', {
        trCount: 3,
        tdCount: 5,
        thCount: 4,
      })

      it('table action - delete table', async () => {
        await insertTable()

        await page.elementLocator(editorElements('td')[0]).click()
        await page.getByRole('button', { name: 'Table options' }).click()

        const popup = await findOpenPopup()
        await popup.getByLabelText('Delete table').click()

        await expect.element(page.getByRole('table')).not.toBeInTheDocument()
      })
    })
  })

  it('should insert code block', async () => {
    await mountEditor()

    const editor = await findEditor()
    await editor.click()
    await page.getByTestId('action-bar').getByLabelText('Insert code block').click()

    const code = page.getByRole('code')

    await expect.element(code).toBeInTheDocument()

    await typeInto(code, 'const vue = "awesome"')

    await expect
      .poll(editorHtml)
      .toContain(
        '<pre dir="auto"><code>const <span class="hljs-attr">vue</span> = <span class="hljs-string">"awesome"</span></code></pre>',
      )
  })

  it('indents list item', async () => {
    await mountEditor()

    const editor = await findEditor()
    await editor.click()
    await page.getByTestId('action-bar').getByLabelText('Add bullet list').click()

    await typeInto(page.getByRole('listitem'), 'First{Enter}Second{Enter}Third')

    await page.getByLabelText('Indent text').click()

    await expect
      .poll(editorHtml)
      .toContain('<li dir="auto" style="margin-left: 1rem;"><p dir="auto">Third</p></li>')

    await page.getByLabelText('Indent text').click()

    await expect
      .poll(editorHtml)
      .toContain('<li dir="auto" style="margin-left: 2rem;"><p dir="auto">Third</p></li>')
  })

  it('outdents list item', async () => {
    await mountEditor()

    const editor = await findEditor()
    await editor.click()
    await page.getByTestId('action-bar').getByLabelText('Add bullet list').click()

    await typeInto(page.getByRole('listitem'), 'First{Enter}Second{Enter}Third')

    await page.getByLabelText('Indent text').click()

    await expect
      .poll(editorHtml)
      .toContain('<li dir="auto" style="margin-left: 1rem;"><p dir="auto">Third</p></li>')

    await page.getByLabelText('Outdent text').click()

    await expect.poll(editorHtml).toContain('<li dir="auto"><p dir="auto">Third</p></li>')
  })

  it('changes text color of item', async () => {
    await mountEditor()

    const editor = await findEditor()
    await userEvent.type(editor, 'world')
    await selectText('left', 5)

    await page.getByTestId('action-bar').getByLabelText('Change text color').click()

    const popup = await findOpenPopup()
    await page
      .elementLocator(
        popup.element().querySelector('[style="background-color: rgb(239, 68, 68);"]')!,
      )
      .click()

    await expect.poll(editorHtml).toContain('<span style="color: rgb(239, 68, 68);">world</span>')
  })
})
