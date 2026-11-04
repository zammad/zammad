// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page } from 'vitest/browser'

import { mountFormField } from '#tests/browser/utils.ts'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'

const mountCheckbox = async (props: Record<string, unknown>) => {
  const view = await mountFormField('checkbox', { label: 'Checkbox', ...props })
  const field = view.container.querySelector<HTMLElement>('.formkit-outer')!

  field.style.minHeight = '24px'

  return page.elementLocator(field)
}

describe('testing visuals for "FieldCheckbox"', () => {
  it('renders default basic checkbox', async () => {
    const field = await mountCheckbox({})

    await expect.element(field).toMatchScreenshot('basic-unchecked')

    await page.getByLabelText('Checkbox').click()

    await expect.element(field).toMatchScreenshot('basic-checked')
  })

  it('renders default required checkbox', async () => {
    const field = await mountCheckbox({ required: true })

    await expect.element(field).toMatchScreenshot('required')
  })

  it('renders checkbox with help', async () => {
    const field = await mountCheckbox({ help: 'Help Message!' })

    await expect.element(field).toMatchScreenshot('help')
  })

  it('renders default invalid checkbox', async () => {
    const field = await mountCheckbox({
      required: true,
      validationVisibility: FormValidationVisibility.Live,
    })

    await expect.element(field).toMatchScreenshot('invalid')
  })

  it('renders default disabled checkbox', async () => {
    const field = await mountCheckbox({ disabled: true })

    await expect.element(field).toMatchScreenshot('disabled')
  })

  it('renders hidden checkbox', async () => {
    const field = await mountCheckbox({ labelSrOnly: true })

    await expect.element(field).toMatchScreenshot('label-sr-only')
  })
})
