// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import CommonButton from '../CommonButton.vue'

describe('CommonButton.vue', () => {
  it('renders with default prop values', async () => {
    const view = renderComponent(CommonButton)

    const button = view.getByRole('button')

    expect(button).toHaveAttribute('type', 'button')
    expect(button).toHaveClasses(['btn', 'btn-secondary', 'btn-sm'])
  })

  it('renders default slot as the button label', async () => {
    const view = renderComponent(CommonButton, {
      slots: {
        default: 'Button',
      },
    })

    expect(view.getByRole('button', { name: 'Button' })).toBeInTheDocument()
  })

  it('supports type prop', async () => {
    const view = renderComponent(CommonButton, {
      props: {
        type: 'submit',
      },
    })

    expect(view.getByRole('button')).toHaveAttribute('type', 'submit')
  })

  it('supports form prop', async () => {
    const view = renderComponent(CommonButton, {
      props: {
        form: 'foobar',
      },
    })

    expect(view.getByRole('button')).toHaveAttribute('form', 'foobar')
  })

  it('supports disabled prop', async () => {
    const view = renderComponent(CommonButton, {
      props: {
        disabled: true,
      },
    })

    expect(view.getByRole('button')).toBeDisabled()
  })

  it('supports block prop', async () => {
    const view = renderComponent(CommonButton, {
      props: {
        block: true,
      },
    })

    expect(view.getByRole('button')).toHaveClasses(['btn-block'])
  })

  it.each([
    {
      variant: 'primary',
      classes: ['btn-primary'],
    },
    {
      variant: 'secondary',
      classes: ['btn-secondary'],
    },
    {
      variant: 'tertiary',
      classes: ['btn-neutral'],
    },
    {
      variant: 'submit',
      classes: ['btn-accent'],
    },
    {
      variant: 'danger',
      classes: ['btn-error'],
    },
    {
      variant: 'remove',
      classes: ['btn-info'],
    },
    {
      variant: 'subtle',
      classes: ['btn-ghost'],
    },
    {
      variant: 'neutral',
      classes: ['btn-secondary'],
    },
  ])('supports $variant variant', async ({ variant, classes }) => {
    const view = renderComponent(CommonButton, {
      props: {
        variant,
      },
    })

    expect(view.getByRole('button')).toHaveClasses(classes)
  })

  it('supports prefix/suffix icon props', async () => {
    const view = renderComponent(CommonButton, {
      props: {
        prefixIcon: 'logo',
        suffixIcon: 'logo',
      },
    })

    expect(view.getAllByIconName('logo').length).toBe(2)
  })

  it('supports icon prop', async () => {
    const view = renderComponent(CommonButton, {
      props: {
        icon: 'logo',
      },
      slots: {
        default: 'foobar',
      },
    })

    expect(view.getByIconName('logo')).toBeInTheDocument()

    expect(
      view.queryByRole('button', { name: 'foobar' }),
    ).not.toBeInTheDocument()
  })
})
