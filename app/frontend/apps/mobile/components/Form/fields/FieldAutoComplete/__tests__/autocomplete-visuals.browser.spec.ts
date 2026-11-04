// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page } from 'vitest/browser'

import { mountFormField } from '#tests/browser/utils.ts'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'

const options = [
  {
    value: 0,
    label: 'Item A',
  },
  {
    value: 1,
    label: 'Item B',
  },
  {
    value: 2,
    label: 'Item C',
  },
  {
    value: 3,
    label: 'Item D',
  },
  {
    value: 4,
    label: 'Item E',
  },
  {
    value: 5,
    label:
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vestibulum sem quis purus elementum pulvinar.',
  },
  {
    value: 6,
    label: 'Item F',
  },
  {
    value: 7,
    label: 'Item G',
  },
  {
    value: 8,
    label: 'Item H',
  },
]

const types = ['customer', 'organization', 'autocomplete', 'recipient']

interface Example {
  title: string
  name: string
  props: Record<string, unknown>
  focused?: boolean
  minHeight?: number
}

const examplesFor = (type: string): Example[] => [
  { title: `renders basic ${type}`, name: 'basic', props: { options } },
  {
    title: `renders basic disabled ${type}`,
    name: 'disabled',
    props: { options, disabled: true },
  },
  {
    title: `renders basic required ${type}`,
    name: 'required',
    props: { options, required: true },
  },
  {
    title: `renders basic invalid ${type}`,
    name: 'invalid',
    props: { options, required: true, validationVisibility: FormValidationVisibility.Live },
  },
  {
    title: `renders basic ${type} with help`,
    name: 'help',
    props: { options, help: 'Help Message!' },
  },
  { title: `renders selected ${type}`, name: 'selected', props: { options, value: 0 } },
  {
    title: `renders selected disabled ${type}`,
    name: 'selected-disabled',
    props: { options, value: 0, disabled: true },
  },
  {
    title: `renders selected required ${type}`,
    name: 'selected-required',
    props: { options, value: 0, required: true },
  },
  {
    title: `renders focused ${type}`,
    name: 'focused',
    props: { options },
    focused: true,
  },
  {
    title: `renders focused linked ${type}`,
    name: 'focused-linked',
    props: { options, link: '/' },
    focused: true,
  },
  {
    title: `renders multiple ${type}`,
    name: 'multiple',
    props: { options, multiple: true, value: [0, 1] },
  },
  {
    title: `renders multiple disabled ${type}`,
    name: 'multiple-disabled',
    props: { options, multiple: true, value: [0, 1], disabled: true },
  },
  {
    title: `renders multiple required ${type}`,
    name: 'multiple-required',
    props: { options, multiple: true, value: [0, 1], required: true },
  },
  {
    title: `renders long ${type}`,
    name: 'long',
    props: { value: 5, options },
    minHeight: 60,
  },
  {
    title: `renders hidden ${type}`,
    name: 'label-sr-only',
    props: { labelSrOnly: true },
  },
  {
    title: `renders selected hidden ${type}`,
    name: 'selected-label-sr-only',
    props: { value: 0, options, labelSrOnly: true },
  },
]

describe('testing visuals for "FieldAutocomplete"', () => {
  describe.for(types)('%s', (type) => {
    it.for(examplesFor(type))('$title', async ({ name, props, focused, minHeight }) => {
      const view = await mountFormField(type, { label: type, ...props })
      const element = view.container.querySelector<HTMLElement>('.formkit-outer')!
      const field = page.elementLocator(element)

      if (focused) {
        const output = page.getByRole('combobox')

        // A click or a key press would open the dialog.
        output.element().focus()

        await expect.element(output).toHaveFocus()
      }

      if (minHeight)
        await expect.poll(() => element.getBoundingClientRect().height).toBeGreaterThan(minHeight)

      await expect.element(field).toMatchScreenshot(`${type}-${name}`)
    })
  })
})
