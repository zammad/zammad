// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page } from 'vitest/browser'

import { mountFormField } from '#tests/browser/utils.ts'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'

const variants = {
  true: 'Yes',
  false: 'No',
}

const mountToggle = async (props: Record<string, unknown>) => {
  const view = await mountFormField('toggle', { label: 'Toggle', ...props })

  return page.elementLocator(view.container.querySelector('.formkit-outer')!)
}

describe('testing visuals for "FieldToggle"', () => {
  it('renders basic toggle', async () => {
    const field = await mountToggle({ variants, value: false })

    await expect.element(field).toMatchScreenshot('basic')

    page.getByRole('switch').element().focus()

    await expect.element(field).toMatchScreenshot('basic-focused')
  })

  it('renders checked toggle', async () => {
    const field = await mountToggle({ variants, value: true })

    await expect.element(field).toMatchScreenshot('checked')
  })

  it('renders disabled toggle', async () => {
    const field = await mountToggle({ variants, disabled: true })

    await expect.element(field).toMatchScreenshot('disabled')
  })

  it('renders invalid toggle', async () => {
    const field = await mountToggle({
      required: true,
      variants,
      validationVisibility: FormValidationVisibility.Live,
    })

    await expect.element(field).toMatchScreenshot('invalid')
  })

  it('renders required toggle', async () => {
    const field = await mountToggle({ variants, required: true })

    await expect.element(field).toMatchScreenshot('required')
  })

  it('renders hidden toggle', async () => {
    const field = await mountToggle({ labelSrOnly: true })

    await expect.element(field).toMatchScreenshot('label-sr-only')
  })

  it('renders toggle with help', async () => {
    const field = await mountToggle({ variants, help: 'Help Message!' })

    await expect.element(field).toMatchScreenshot('help')
  })
})
