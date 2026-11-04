// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page } from 'vitest/browser'

import { mountFormField } from '#tests/browser/utils.ts'

const radioOptions = [
  { label: 'Incoming Phone', value: 1, icon: 'phone-in' },
  { label: 'Outgoing Phone', value: 2, icon: 'phone-out' },
  { label: 'Send Email', value: 3, icon: 'mail-out' },
]

const mountRadio = async (props: Record<string, unknown>) => {
  const view = await mountFormField('radio', props)

  return page.elementLocator(view.container.querySelector('.formkit-outer')!)
}

describe('testing visuals for "FieldRadio"', () => {
  it('renders as buttons', async () => {
    const field = await mountRadio({ buttons: true, options: radioOptions })

    await expect.element(field).toMatchScreenshot('buttons')

    await page.getByText('Incoming Phone').click()

    await expect.element(field).toMatchScreenshot('buttons-checked')
  })

  it('renders as disabled buttons', async () => {
    const field = await mountRadio({ buttons: true, disabled: true, options: radioOptions })

    await expect.element(field).toMatchScreenshot('buttons-disabled')
  })

  it('renders hidden radio', async () => {
    const field = await mountRadio({ label: 'Radio', labelSrOnly: true })

    await expect.element(field).toMatchScreenshot('label-sr-only')
  })
})
