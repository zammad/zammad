// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page } from 'vitest/browser'

import { mountFormField } from '#tests/browser/utils.ts'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'

const mountDate = async (type: string, props: Record<string, unknown>) => {
  const view = await mountFormField(type, { id: 'datetime', ...props })

  return page.elementLocator(view.container.querySelector('.formkit-outer')!)
}

describe('testing visuals for "FieldDate"', () => {
  const inputs = [
    { type: 'date', value: '2021-01-01' },
    { type: 'datetime', value: '2021-01-01T13:12:00Z' },
  ]

  inputs.forEach(({ type, value }) => {
    // The panel's "Choose date" label would match as well, once it is open.
    const getInput = () => page.getByLabelText('Date', { exact: true })

    it(`renders basic ${type}`, async () => {
      const field = await mountDate(type, { label: 'Date', maxDate: '2021-01-31' })

      await expect.element(field).toMatchScreenshot(`${type}-basic`)

      getInput().element().focus()
      await expect.element(field).toMatchScreenshot(`${type}-basic-focused`)

      await getInput().click()
      await expect.element(field).toMatchScreenshot(`${type}-basic-open`)
    })

    it(`renders filled ${type}`, async () => {
      const field = await mountDate(type, { label: 'Date', maxDate: '2021-01-31', value })

      await expect.element(field).toMatchScreenshot(`${type}-filled`)
    })

    it(`renders help for ${type}`, async () => {
      const field = await mountDate(type, {
        label: 'Date',
        maxDate: '2021-01-31',
        help: 'Help message!',
      })

      await expect.element(field).toMatchScreenshot(`${type}-help`)
    })

    it(`renders required ${type}`, async () => {
      const field = await mountDate(type, { label: 'Date', required: true, maxDate: '2021-01-31' })

      await expect.element(field).toMatchScreenshot(`${type}-required`)

      getInput().element().focus()
      await expect.element(field).toMatchScreenshot(`${type}-required-focused`)
    })

    it(`renders invalid ${type}`, async () => {
      const field = await mountDate(type, {
        label: 'Date',
        required: true,
        maxDate: '2021-01-31',
        validationVisibility: FormValidationVisibility.Live,
      })

      await expect.element(field).toMatchScreenshot(`${type}-invalid`)
    })

    it(`renders linked ${type}`, async () => {
      const field = await mountDate(type, {
        label: 'Date',
        link: '/',
        maxDate: '2021-01-31',
        value,
      })

      await expect.element(field).toMatchScreenshot(`${type}-linked`)
    })

    it(`renders disabled ${type}`, async () => {
      const field = await mountDate(type, { label: 'Date', disabled: true, maxDate: '2021-01-31' })

      await expect.element(field).toMatchScreenshot(`${type}-disabled`)
    })

    it(`renders hidden ${type}`, async () => {
      const field = await mountDate(type, { label: type, labelSrOnly: true, value })

      await expect.element(field).toMatchScreenshot(`${type}-label-sr-only`)
    })
  })
})
