// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page } from 'vitest/browser'

import { mountFormField } from '#tests/browser/utils.ts'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'

const options = [
  {
    value: 0,
    label: 'Item A',
    children: [
      {
        value: 1,
        label: 'Item 1',
        children: [
          {
            value: 2,
            label: 'Item I',
          },
          {
            value: 3,
            label: 'Item II',
          },
          {
            value: 4,
            label: 'Item III',
          },
        ],
      },
      {
        value: 5,
        label:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vestibulum sem quis purus elementum pulvinar.',
        children: [
          {
            value: 6,
            label: 'Item IV',
          },
        ],
      },
      {
        value: 7,
        label: 'Item 3',
      },
    ],
  },
  {
    value: 8,
    label: 'Item B',
  },
  {
    value: 9,
    label: 'Ítem C',
  },
]

const value = 0

const mountTreeSelect = async (props: Record<string, unknown>) => {
  const view = await mountFormField('treeselect', { label: 'treeselect', ...props })

  return page.elementLocator(view.container.querySelector<HTMLElement>('.formkit-outer')!)
}

// A click or a key press would open the dialog.
const focusTreeSelect = async () => {
  const output = page.getByRole('combobox')

  output.element().focus()

  await expect.element(output).toHaveFocus()
}

describe('testing visuals for "FieldTreeSelect"', () => {
  it('renders basic disabled treeselect', async () => {
    const field = await mountTreeSelect({ disabled: true })

    await expect.element(field).toMatchScreenshot('disabled')
  })

  it('renders basic required treeselect', async () => {
    const field = await mountTreeSelect({ required: true })

    await expect.element(field).toMatchScreenshot('required')
  })

  it('renders basic invalid treeselect', async () => {
    const field = await mountTreeSelect({
      required: true,
      validationVisibility: FormValidationVisibility.Live,
    })

    await expect.element(field).toMatchScreenshot('invalid')
  })

  it('renders focused treeselect', async () => {
    const field = await mountTreeSelect({})

    await focusTreeSelect()

    await expect.element(field).toMatchScreenshot('focused')
  })

  it('renders focused linked treeselect', async () => {
    const field = await mountTreeSelect({ link: '/' })

    await focusTreeSelect()

    await expect.element(field).toMatchScreenshot('focused-linked')
  })

  it('renders linked treeselect', async () => {
    const field = await mountTreeSelect({ link: '/' })

    await expect.element(field).toMatchScreenshot('linked')
  })

  it('renders selected treeselect', async () => {
    const field = await mountTreeSelect({ options, value })

    await expect.element(field).toMatchScreenshot('selected')
  })

  it('renders selected disabled treeselect', async () => {
    const field = await mountTreeSelect({ options, value, disabled: true })

    await expect.element(field).toMatchScreenshot('selected-disabled')
  })

  it('renders selected required treeselect', async () => {
    const field = await mountTreeSelect({ options, value, required: true })

    await expect.element(field).toMatchScreenshot('selected-required')
  })

  it('renders selected treeselect linked', async () => {
    const field = await mountTreeSelect({ options, value, link: '/' })

    await expect.element(field).toMatchScreenshot('selected-linked')
  })

  it('renders multiple selected treeselect', async () => {
    const field = await mountTreeSelect({ options, value: [0, 1], multiple: true })

    await expect.element(field).toMatchScreenshot('multiple')
  })

  it('renders multiple selected disabled treeselect', async () => {
    const field = await mountTreeSelect({
      options,
      value: [0, 1],
      multiple: true,
      disabled: true,
    })

    await expect.element(field).toMatchScreenshot('multiple-disabled')
  })

  it('renders multiple selected required treeselect', async () => {
    const field = await mountTreeSelect({
      options,
      value: [0, 1],
      multiple: true,
      required: true,
    })

    await expect.element(field).toMatchScreenshot('multiple-required')
  })

  it('renders long multiple selected', async () => {
    const field = await mountTreeSelect({
      options,
      value: [0, 1, 2, 3, 4, 6, 7, 8],
      multiple: true,
    })

    await expect.element(field).toMatchScreenshot('long-multiple')
  })

  it('renders long selected', async () => {
    const field = await mountTreeSelect({ options, value: 5 })

    await expect.element(field).toMatchScreenshot('long')
  })

  it('renders hidden treeselect', async () => {
    const field = await mountTreeSelect({ labelSrOnly: true })

    await expect.element(field).toMatchScreenshot('label-sr-only')
  })

  it('renders treeselect with help', async () => {
    const field = await mountTreeSelect({ help: 'Help Message!' })

    await expect.element(field).toMatchScreenshot('help')
  })

  it('renders selected hidden treeselect', async () => {
    const field = await mountTreeSelect({ value: 1, options, labelSrOnly: true })

    await expect.element(field).toMatchScreenshot('selected-label-sr-only')
  })
})
