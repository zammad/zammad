// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent, type Locator } from 'vitest/browser'

import { mountFormField } from '#tests/browser/utils.ts'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'

const mountInput = async (type: string, props: Record<string, unknown> = {}) => {
  const view = await mountFormField(type, { label: type, ...props })

  return page.elementLocator(view.container.querySelector('.formkit-outer')!)
}

describe('testing visuals for "FieldInput"', () => {
  const inputs = [
    { type: 'text', input: 'Some Text' },
    { type: 'email', input: 'some@mail.com' },
    { type: 'number', input: '100' },
    { type: 'tel', input: '123456789' },
    { type: 'time', input: '12:12' },
  ]

  inputs.forEach(({ type, input }) => {
    const focusAndFill = async (field: Locator, name: string) => {
      const element = page.getByLabelText(type, { exact: true })

      element.element().focus()
      await expect.element(field).toMatchScreenshot(`${type}-${name}-focused`)

      await userEvent.fill(element, input)
      await expect.element(field).toMatchScreenshot(`${type}-${name}-filled`)
    }

    it(`renders usual ${type}`, async () => {
      const field = await mountInput(type)

      await expect.element(field).toMatchScreenshot(`${type}-basic`)
      await focusAndFill(field, 'basic')
    })

    it(`renders required ${type}`, async () => {
      const field = await mountInput(type, { required: true })

      await expect.element(field).toMatchScreenshot(`${type}-required`)
      await focusAndFill(field, 'required')
    })

    it(`renders invalid ${type}`, async () => {
      const field = await mountInput(type, {
        required: true,
        validationVisibility: FormValidationVisibility.Live,
      })

      await expect.element(field).toMatchScreenshot(`${type}-invalid`)
    })

    it(`renders ${type} with help`, async () => {
      const field = await mountInput(type, { help: 'Help message!' })

      await expect.element(field).toMatchScreenshot(`${type}-help`)
    })

    it(`renders linked ${type}`, async () => {
      const field = await mountInput(type, { link: '/' })

      await expect.element(field).toMatchScreenshot(`${type}-linked`)
      await focusAndFill(field, 'linked')
    })

    it(`renders disabled ${type}`, async () => {
      const field = await mountInput(type, { disabled: true })

      await expect.element(field).toMatchScreenshot(`${type}-disabled`)
    })

    it(`renders hidden ${type}`, async () => {
      const field = await mountInput(type, { labelSrOnly: true })

      await expect.element(field).toMatchScreenshot(`${type}-label-sr-only`)

      await userEvent.fill(page.getByLabelText(type, { exact: true }), input)
      await expect.element(field).toMatchScreenshot(`${type}-label-sr-only-filled`)
    })
  })
})
