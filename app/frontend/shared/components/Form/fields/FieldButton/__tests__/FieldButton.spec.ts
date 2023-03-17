// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import type { ExtendedMountingOptions } from '@tests/support/components'
import { renderComponent } from '@tests/support/components'

const wrapperParameters = {
  form: true,
  formField: true,
}

const renderButton = (options: ExtendedMountingOptions<any> = {}) => {
  return renderComponent(FormKit, {
    ...wrapperParameters,
    props: {
      name: 'button',
      type: 'button',
      id: 'button',
    },
    slots: {
      default: 'Sign In',
    },
    ...options,
  })
}

describe('Form - Field - Button (Formkit-BuildIn)', () => {
  it('can render a button', () => {
    const view = renderButton()

    const button = view.getByText('Sign In')

    expect(button).toHaveAttribute('id', 'button')
    expect(button.closest('div')).toHaveAttribute('data-variant', 'primary')
  })

  it('can render a button with a label instead of slot', () => {
    const view = renderButton({
      props: {
        name: 'button',
        type: 'button',
        id: 'button',
        label: 'Sign In',
      },
    })

    expect(view.getByText('Sign In')).toBeInTheDocument()
  })

  it('can use different variant', () => {
    const view = renderButton({
      props: {
        name: 'button',
        type: 'button',
        id: 'button',
        label: 'Sign In',
        variant: 'secondary',
      },
    })

    expect(view.getByText('Sign In').closest('div')).toHaveAttribute(
      'data-variant',
      'secondary',
    )
  })

  it('can be disabled', async () => {
    const view = renderButton({
      props: {
        name: 'button',
        type: 'button',
        id: 'button',
        label: 'Sign In',
      },
    })

    const button = view.getByText('Sign In')

    expect(button).not.toHaveAttribute('disabled')

    await view.rerender({
      disabled: true,
    })

    expect(button).toHaveAttribute('disabled')

    // Rest the disabled state again and check if it's enabled again.
    await view.rerender({
      disabled: false,
    })

    expect(button).not.toHaveAttribute('disabled')
  })

  it('can use icons', async () => {
    const view = renderButton({
      props: {
        name: 'button',
        type: 'button',
        id: 'button',
        label: 'Sign In',
        icon: 'mobile-arrow-right',
      },
    })

    const icon = view.getByIconName('mobile-arrow-right')

    expect(icon).toBeInTheDocument()
  })

  it('can trigger action on icon', async () => {
    const iconClickSpy = vi.fn()

    const view = renderButton({
      props: {
        name: 'button',
        type: 'button',
        id: 'button',
        label: 'Sign In',
        icon: 'mobile-arrow-right',
        onIconClick: iconClickSpy,
      },
    })

    const icon = view.getByIconName('mobile-arrow-right')

    await view.events.click(icon)

    expect(iconClickSpy).toHaveBeenCalledTimes(1)
  })
})

describe('Form - Field - Submit-Button (Formkit-BuildIn)', () => {
  it('can render a button', () => {
    const view = renderButton({
      props: {
        name: 'submit',
        type: 'submit',
        id: 'submit',
      },
      slots: {
        default: 'Sign In',
      },
    })

    const button = view.getByText('Sign In')
    expect(button).toBeInTheDocument()
    expect(button).toHaveAttribute('id', 'submit')
    expect(button).toHaveAttribute('type', 'submit')
  })
})
