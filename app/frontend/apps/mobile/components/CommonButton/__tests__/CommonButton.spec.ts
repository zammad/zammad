// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonButton from '../CommonButton.vue'

describe('CommonButton.vue', () => {
  it('renders with default prop values', async () => {
    const view = renderComponent(CommonButton)

    const button = view.getByRole('button')

    expect(button).toHaveAttribute('type', 'button')
    expect(button).toHaveClasses(['bg-gray-500', 'text-white'])
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

    expect(view.getByRole('button')).toHaveAttribute('disabled')
  })

  it.each([
    {
      variant: 'primary',
      classes: ['bg-blue', 'text-white'],
    },
    {
      variant: 'secondary',
      classes: ['bg-gray-500', 'text-white'],
    },
    {
      variant: 'submit',
      classes: ['bg-yellow', 'font-semibold', 'text-black-full'],
    },
    {
      variant: 'danger',
      classes: ['bg-red-dark', 'text-red-bright'],
    },
  ])('supports $variant variant', async ({ variant, classes }) => {
    const view = renderComponent(CommonButton, {
      props: {
        variant,
      },
    })

    expect(view.getByRole('button')).toHaveClasses(classes)
  })

  it.each([
    {
      variant: 'primary',
      classes: ['text-blue'],
    },
    {
      variant: 'secondary',
      classes: ['text-white'],
    },
    {
      variant: 'submit',
      classes: ['font-semibold', 'text-yellow'],
    },
    {
      variant: 'danger',
      classes: ['text-red-bright'],
    },
  ])(
    'supports $variant variant with transparent background',
    async ({ variant, classes }) => {
      const view = renderComponent(CommonButton, {
        props: {
          variant,
          transparentBackground: true,
        },
      })

      const button = view.getByRole('button')

      expect(button).toHaveClass('bg-transparent')
      expect(button).toHaveClasses(classes)
    },
  )
})
