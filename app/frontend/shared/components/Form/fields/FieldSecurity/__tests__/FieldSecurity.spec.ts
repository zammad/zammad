// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { renderComponent } from '@tests/support/components'

const renderSecurityField = (props: any = {}) => {
  return renderComponent(FormKit, {
    form: true,
    formField: true,
    props: {
      type: 'security',
      name: 'security',
      label: 'Security',
      ...props,
    },
  })
}

describe('FieldSecurity', () => {
  it('renders security options', async () => {
    const view = renderSecurityField({
      allowed: ['encryption', 'sign'],
    })

    const encrypt = view.getByRole('option', { name: 'Encrypt' })
    const sign = view.getByRole('option', { name: 'Sign' })

    expect(encrypt).toBeInTheDocument()
    expect(sign).toBeInTheDocument()

    expect(encrypt).toBeEnabled()
    expect(sign).toBeEnabled()
  })

  it('can check and uncheck options', async () => {
    const view = renderSecurityField({
      allowed: ['encryption', 'sign'],
    })

    const encrypt = view.getByRole('option', { name: 'Encrypt' })
    const sign = view.getByRole('option', { name: 'Sign' })

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(encrypt)

    expect(encrypt).toHaveAttribute('aria-selected', 'true')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(encrypt)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(sign)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'true')

    await view.events.click(sign)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')
  })

  it("doesn't check disabled options", async () => {
    const view = renderSecurityField({
      allowed: [],
    })

    const encrypt = view.getByRole('option', { name: 'Encrypt' })
    const sign = view.getByRole('option', { name: 'Sign' })

    expect(encrypt).toBeDisabled()
    expect(sign).toBeDisabled()

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(encrypt)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(encrypt)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')
  })
})
