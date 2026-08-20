// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { getAllByRole, waitFor } from '@testing-library/vue'

import { renderComponent, type ExtendedRenderResult } from '#tests/support/components/index.ts'

import {
  mockAutocompleteSearchKnowledgeBaseCategoryIconQuery,
  waitForAutocompleteSearchKnowledgeBaseCategoryIconQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/autocompleteSearchCategoryIcon.mocks.ts'
import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'

import type { AutoCompleteKnowledgeBaseCategoryIconOption } from '../types.ts'

const wrapperParameters = {
  form: true,
  router: true,
  dialog: true,
  store: true,
}

const testProps = {
  type: 'kbCategoryIcon',
  label: 'Icon',
  // Pinned, so the field does not depend on the knowledge base store having loaded.
  iconSet: 'FontAwesome',
  debounceInterval: 0,
}

const folderIcon: AutoCompleteKnowledgeBaseCategoryIconOption = {
  __typename: 'AutocompleteSearchKnowledgeBaseCategoryIconEntry',
  value: 'f115',
  label: 'Folder Open',
  iconSet: 'FontAwesome',
}

const glassIcon: AutoCompleteKnowledgeBaseCategoryIconOption = {
  __typename: 'AutocompleteSearchKnowledgeBaseCategoryIconEntry',
  value: 'f000',
  label: 'Glass',
  iconSet: 'FontAwesome',
}

const testOptions = [folderIcon, glassIcon]

// The catalog is loaded eagerly on mount, since the picker is meant to be browsed.
const renderField = async (props: Record<string, unknown> = {}) => {
  mockAutocompleteSearchKnowledgeBaseCategoryIconQuery({
    autocompleteSearchKnowledgeBaseCategoryIcon: testOptions,
  })

  const wrapper = renderComponent(FormKit, {
    ...wrapperParameters,
    props: { ...testProps, ...props },
  })

  await waitForAutocompleteSearchKnowledgeBaseCategoryIconQueryCalls()

  return wrapper
}

const openDropdown = async (wrapper: ExtendedRenderResult) => {
  await wrapper.events.click(await wrapper.findByLabelText('Icon'))

  return wrapper.getByRole('menu')
}

// The shared icon queries only match the app-internal `#icon-…` sprite, while the
//   category icon references an external icon font file.
const getSpriteHref = (element: Element) =>
  element.querySelector('use')?.getAttribute('href') ?? undefined

describe('Form - Field - KnowledgeBaseCategoryIcon - Query', () => {
  it('browses the whole catalog of the active icon set on opening', async () => {
    const wrapper = await renderField()

    const calls = await waitForAutocompleteSearchKnowledgeBaseCategoryIconQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({ query: '*', iconSet: 'FontAwesome' }),
    })

    const options = getAllByRole(await openDropdown(wrapper), 'option')

    expect(options).toHaveLength(testOptions.length)
  })

  it('filters the catalog by the typed name', async () => {
    const wrapper = await renderField()

    await openDropdown(wrapper)

    mockAutocompleteSearchKnowledgeBaseCategoryIconQuery({
      autocompleteSearchKnowledgeBaseCategoryIcon: [folderIcon],
    })

    await wrapper.events.type(wrapper.getByRole('searchbox'), 'folder')

    const calls = await waitForAutocompleteSearchKnowledgeBaseCategoryIconQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({ query: 'folder', iconSet: 'FontAwesome' }),
    })

    await waitFor(() => {
      expect(getAllByRole(wrapper.getByRole('menu'), 'option')).toHaveLength(1)
    })

    expect(getAllByRole(wrapper.getByRole('menu'), 'option')[0]).toHaveAccessibleName(
      folderIcon.label,
    )
  })

  it('filters the catalog by a keyword of an icon, not only its name', async () => {
    const wrapper = await renderField()

    await openDropdown(wrapper)

    // 'martini' is a FontAwesome keyword of the icon named 'Glass' — the backend
    //   matches it, so the field has to render what comes back for a filter that
    //   does not occur in any label.
    mockAutocompleteSearchKnowledgeBaseCategoryIconQuery({
      autocompleteSearchKnowledgeBaseCategoryIcon: [glassIcon],
    })

    await wrapper.events.type(wrapper.getByRole('searchbox'), 'martini')

    await waitForAutocompleteSearchKnowledgeBaseCategoryIconQueryCalls()

    await waitFor(() => {
      expect(getAllByRole(wrapper.getByRole('menu'), 'option')).toHaveLength(1)
    })

    expect(getAllByRole(wrapper.getByRole('menu'), 'option')[0]).toHaveAccessibleName(
      glassIcon.label,
    )
  })

  it('searches the catalog of a switched icon set', async () => {
    mockAutocompleteSearchKnowledgeBaseCategoryIconQuery({
      autocompleteSearchKnowledgeBaseCategoryIcon: [
        { value: 'e94d', label: 'Folder', iconSet: 'material' },
      ],
    })

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: { ...testProps, iconSet: 'material' },
    })

    const calls = await waitForAutocompleteSearchKnowledgeBaseCategoryIconQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({ iconSet: 'material' }),
    })

    const options = getAllByRole(await openDropdown(wrapper), 'option')

    // Each entry carries the set it was found in, so the cell renders from the
    //   matching sprite rather than a set assumed by the field.
    expect(getSpriteHref(options[0])).toBe('/assets/icon-fonts/material.svg#icon-e94d')
  })

  it('falls back to the icon set of the browsed knowledge base', async () => {
    mockKnowledgeBaseQuery({ knowledgeBase: { iconset: 'ionicons' } })
    mockAutocompleteSearchKnowledgeBaseCategoryIconQuery({
      autocompleteSearchKnowledgeBaseCategoryIcon: [],
    })

    renderComponent(FormKit, {
      ...wrapperParameters,
      props: { ...testProps, iconSet: undefined },
    })

    const calls = await waitForAutocompleteSearchKnowledgeBaseCategoryIconQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({ iconSet: 'ionicons' }),
    })
  })

  it('searches the switched catalog and re-renders the stored icon from it', async () => {
    const wrapper = await renderField({ value: glassIcon.value })

    expect(getSpriteHref(wrapper.getByRole('listitem'))).toBe(
      `/assets/icon-fonts/FontAwesome.svg#icon-${glassIcon.value}`,
    )

    mockAutocompleteSearchKnowledgeBaseCategoryIconQuery({
      autocompleteSearchKnowledgeBaseCategoryIcon: [],
    })

    await wrapper.rerender({ ...testProps, value: glassIcon.value, iconSet: 'material' })

    const calls = await waitForAutocompleteSearchKnowledgeBaseCategoryIconQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({ iconSet: 'material' }),
    })

    // The stored codepoint carries no icon set of its own, so the collapsed field has
    //   to follow the switched one instead of the set it was first rendered with.
    await waitFor(() => {
      expect(getSpriteHref(wrapper.getByRole('listitem'))).toBe(
        `/assets/icon-fonts/material.svg#icon-${glassIcon.value}`,
      )
    })
  })

  it('renders a graceful empty state when nothing matches', async () => {
    const wrapper = await renderField()

    await openDropdown(wrapper)

    mockAutocompleteSearchKnowledgeBaseCategoryIconQuery({
      autocompleteSearchKnowledgeBaseCategoryIcon: [],
    })

    await wrapper.events.type(wrapper.getByRole('searchbox'), 'nonexistent')

    await waitForAutocompleteSearchKnowledgeBaseCategoryIconQueryCalls()

    await waitFor(() => {
      expect(wrapper.getByText('No results found')).toBeInTheDocument()
    })

    // The empty state is a plain, non-interactive row — no icon cell survives it.
    expect(wrapper.getByRole('menu').querySelector('use')).toBeNull()
  })
})

describe('Form - Field - KnowledgeBaseCategoryIcon - Selection', () => {
  it('sets the value to the codepoint of the picked icon', async () => {
    const wrapper = await renderField()

    const options = getAllByRole(await openDropdown(wrapper), 'option')

    await wrapper.events.click(options[1])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(glassIcon.value)
  })

  it('renders the picked icon and its label in the collapsed field', async () => {
    const wrapper = await renderField()

    const options = getAllByRole(await openDropdown(wrapper), 'option')

    await wrapper.events.click(options[0])

    const selected = wrapper.getByRole('listitem')

    expect(getSpriteHref(selected)).toBe(
      `/assets/icon-fonts/FontAwesome.svg#icon-${folderIcon.value}`,
    )

    expect(selected).toHaveTextContent('Folder Open')
  })

  it('renders an already stored codepoint without knowing its name yet', async () => {
    const wrapper = await renderField({ value: glassIcon.value })

    const selected = wrapper.getByRole('listitem')

    expect(getSpriteHref(selected)).toBe(
      `/assets/icon-fonts/FontAwesome.svg#icon-${glassIcon.value}`,
    )
  })

  it('marks the stored icon as selected in the grid', async () => {
    const wrapper = await renderField({ value: glassIcon.value })

    const options = getAllByRole(await openDropdown(wrapper), 'option')

    expect(options[0]).toHaveAttribute('aria-selected', 'false')
    expect(options[1]).toHaveAttribute('aria-selected', 'true')
  })
})

describe('Form - Field - KnowledgeBaseCategoryIcon - Accessibility', () => {
  it('lays the options out as a grid of named, selectable cells', async () => {
    const wrapper = await renderField()

    const options = getAllByRole(await openDropdown(wrapper), 'option')

    expect(options[0].parentElement).toHaveClass('flex', 'flex-wrap')

    options.forEach((option, index) => {
      expect(option).toHaveAttribute('aria-selected', 'false')
      expect(option).toHaveAccessibleName(testOptions[index].label)
      // The name is carried by the cell, so the sprite itself stays decorative.
      expect(option.querySelector('svg')).toHaveAttribute('aria-hidden', 'true')
    })
  })

  it('provides a labeled search input', async () => {
    const wrapper = await renderField()

    await openDropdown(wrapper)

    expect(wrapper.getByRole('searchbox')).toHaveAccessibleName('Search…')
  })

  it('traverses the grid along its rows and picks with the keyboard', async () => {
    const wrapper = await renderField()

    const options = getAllByRole(await openDropdown(wrapper), 'option')

    await wrapper.events.keyboard('{ArrowDown}')

    expect(options[0]).toHaveFocus()

    // Grid cells are traversed horizontally, since a row holds more than one.
    await wrapper.events.keyboard('{ArrowRight}')

    expect(options[1]).toHaveFocus()

    await wrapper.events.keyboard('{Enter}')

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(glassIcon.value)
  })
})
