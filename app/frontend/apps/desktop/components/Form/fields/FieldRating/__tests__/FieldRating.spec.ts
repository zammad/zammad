// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

const renderRatingField = (props: any = {}) => {
  return renderComponent(FormKit, {
    form: true,
    props: {
      id: 'rating',
      type: 'rating',
      name: 'rating',
      label: 'How would you rate Zammad?',
      ...props,
    },
  })
}

describe('Form - Field - Rating', () => {
  it.each([1, 2, 3, 4, 5])('renders rating star %s', async (star) => {
    const view = renderRatingField()

    const node = getNode('rating')!

    const starIcon = view.getByTestId(`field-rating-star-${star}`)

    expect(node.context?.value).toBeUndefined()
    expect(starIcon).toHaveClasses(['icon-star'])

    await view.events.click(starIcon)

    expect(node.context?.value).toEqual(star.toString())
    expect(starIcon).toHaveClasses(['text-contrast', 'icon-star-fill'])
  })

  it.each([
    {
      star: 1,
      dir: EnumTextDirection.Ltr,
    },
    {
      star: 2,
      dir: EnumTextDirection.Ltr,
    },
    {
      star: 3,
      dir: EnumTextDirection.Ltr,
    },
    {
      star: 4,
      dir: EnumTextDirection.Ltr,
    },
    {
      star: 5,
      dir: EnumTextDirection.Ltr,
    },
    {
      star: 1,
      dir: EnumTextDirection.Rtl,
    },
    {
      star: 2,
      dir: EnumTextDirection.Rtl,
    },
    {
      star: 3,
      dir: EnumTextDirection.Rtl,
    },
    {
      star: 4,
      dir: EnumTextDirection.Rtl,
    },
    {
      star: 5,
      dir: EnumTextDirection.Rtl,
    },
  ])('supports horizontal keyboard control ($star, $dir)', async ({ star, dir }) => {
    const locale = useLocaleStore()

    locale.localeData = { dir } as any

    const previousValue = star === 1 ? '' : (star - 1).toString()
    const newValue = star.toString()

    const view = renderRatingField({
      value: previousValue,
    })

    const node = getNode('rating')!

    const input = view.getByTestId('field-rating-input')
    const starIcon = view.getByTestId(`field-rating-star-${star}`)

    expect(starIcon).toHaveClass('icon-star')

    // Increase rating.
    await view.events.type(input, `{Arrow${dir === EnumTextDirection.Ltr ? 'Right' : 'Left'}}`)

    await waitFor(() => {
      expect(node.context?.value).toBe(newValue)
      expect(starIcon).toHaveClasses(['text-contrast', 'icon-star-fill'])
    })

    // Decrease rating.
    await view.events.type(input, `{Arrow${dir === EnumTextDirection.Ltr ? 'Left' : 'Right'}}`)

    await waitFor(() => {
      expect(node.context?.value).toBe(previousValue)
      expect(starIcon).toHaveClass('icon-star')
    })
  })

  it.each([1, 2, 3, 4, 5])('supports vertical keyboard control (%s)', async (star) => {
    const previousValue = star === 1 ? '' : (star - 1).toString()
    const newValue = star.toString()

    const view = renderRatingField({
      value: previousValue,
    })

    const node = getNode('rating')!

    const input = view.getByTestId('field-rating-input')
    const starIcon = view.getByTestId(`field-rating-star-${star}`)

    expect(starIcon).toHaveClass('icon-star')

    // Increase rating.
    await view.events.type(input, '{ArrowUp}')

    await waitFor(() => {
      expect(node.context?.value).toBe(newValue)
      expect(starIcon).toHaveClasses(['text-contrast', 'icon-star-fill'])
    })

    // Decrease rating.
    await view.events.type(input, '{ArrowDown}')

    await waitFor(() => {
      expect(node.context?.value).toBe(previousValue)
      expect(starIcon).toHaveClass('icon-star')
    })
  })

  it('is exposed to screen readers as a spinbutton', async () => {
    const view = renderRatingField()

    const spinbutton = view.getByRole('spinbutton', { name: 'How would you rate Zammad?' })

    expect(spinbutton).toHaveAttribute('aria-valuemin', '1')
    expect(spinbutton).toHaveAttribute('aria-valuemax', '5')
    expect(spinbutton).not.toHaveAttribute('aria-valuenow')
    expect(spinbutton).toHaveAttribute('aria-valuetext', 'No rating')

    await view.events.click(view.getByTestId('field-rating-star-3'))

    expect(spinbutton).toHaveAttribute('aria-valuenow', '3')
    expect(spinbutton).toHaveAttribute('aria-valuetext', '3 of 5 stars')
  })

  it('supports home and end keys', async () => {
    const view = renderRatingField({
      value: '3',
    })

    const node = getNode('rating')!

    const spinbutton = view.getByRole('spinbutton')

    await view.events.type(spinbutton, '{End}')

    await waitFor(() => {
      expect(node.context?.value).toBe('5')
    })

    await view.events.type(spinbutton, '{Home}')

    await waitFor(() => {
      expect(node.context?.value).toBe('1')
    })
  })

  it.each(['{ArrowDown}', '{ArrowLeft}'])('does not clear a required rating (%s)', async (key) => {
    useLocaleStore().localeData = { dir: EnumTextDirection.Ltr } as any

    const view = renderRatingField({
      value: '1',
      required: true,
    })

    const node = getNode('rating')!

    const spinbutton = view.getByRole('spinbutton')

    await view.events.type(spinbutton, key)

    expect(node.context?.value).toBe('1')
    expect(spinbutton).toHaveAttribute('aria-valuenow', '1')
  })

  it('describes the rating with its validation error', async () => {
    const view = renderRatingField({
      required: true,
      validationVisibility: 'live',
    })

    const spinbutton = view.getByRole('spinbutton')

    expect(spinbutton).toHaveAttribute('aria-required', 'true')
    expect(spinbutton).toHaveAttribute('aria-invalid', 'true')
    expect(spinbutton).toHaveAccessibleDescription('This field is required.')

    await view.events.click(view.getByTestId('field-rating-star-4'))

    await waitFor(() => {
      expect(spinbutton).not.toHaveAttribute('aria-invalid')
      expect(spinbutton).not.toHaveAccessibleDescription()
    })
  })

  it('cannot be changed when disabled', async () => {
    const view = renderRatingField({
      value: '2',
      disabled: true,
    })

    const node = getNode('rating')!

    const spinbutton = view.getByRole('spinbutton')

    expect(spinbutton).toHaveAttribute('aria-disabled', 'true')

    await view.events.click(view.getByTestId('field-rating-star-5'))
    await view.events.type(spinbutton, '{ArrowUp}')

    expect(node.context?.value).toBe('2')
  })
})
