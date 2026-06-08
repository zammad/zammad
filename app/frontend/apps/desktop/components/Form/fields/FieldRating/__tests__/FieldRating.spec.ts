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
    formField: true,
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

    expect(node.context?.value).toBe('')
    expect(starIcon).toHaveClasses(['icon-star'])

    await view.events.click(starIcon)

    expect(node.context?.value).toEqual(star.toString())
    expect(starIcon).toHaveClasses(['text-black', 'dark:text-white', 'icon-star-fill'])
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
    const newValue = (star - 1).toString()

    const view = renderRatingField({
      value: previousValue,
    })

    const node = getNode('rating')!

    const input = view.getByTestId('field-rating-input')
    const starIcon = view.getByTestId(`field-rating-star-${star}`)

    expect(starIcon).toHaveClass('icon-star')

    // Increase rating.
    await view.events.type(input, `{Arrow${dir === EnumTextDirection.Ltr ? 'Right' : 'Left'}}`)

    waitFor(() => {
      expect(node.context?.value).toBe(newValue)
      expect(starIcon).toHaveClasses(['text-black', 'dark:text-white', 'icon-star-fill'])
    })

    // Decrease rating.
    await view.events.type(input, `{Arrow${dir === EnumTextDirection.Ltr ? 'Left' : 'Right'}}`)

    waitFor(() => {
      expect(node.context?.value).toBe(previousValue)
      expect(starIcon).toHaveClass('icon-star')
    })
  })

  it.each([1, 2, 3, 4, 5])('supports vertical keyboard control (%s)', async (star) => {
    const previousValue = star === 1 ? '' : (star - 1).toString()
    const newValue = (star - 1).toString()

    const view = renderRatingField({
      value: previousValue,
    })

    const node = getNode('rating')!

    const input = view.getByTestId('field-rating-input')
    const starIcon = view.getByTestId(`field-rating-star-${star}`)

    expect(starIcon).toHaveClass('icon-star')

    // Increase rating.
    await view.events.type(input, '{ArrowUp}')

    waitFor(() => {
      expect(node.context?.value).toBe(newValue)
      expect(starIcon).toHaveClasses(['text-black', 'dark:text-white', 'icon-star-fill'])
    })

    // Decrease rating.
    await view.events.type(input, '{ArrowDown}')

    waitFor(() => {
      expect(node.context?.value).toBe(previousValue)
      expect(starIcon).toHaveClass('icon-star')
    })
  })

  it.each([1, 2, 3, 4, 5])('supports screen readers (%s)', async (star) => {
    const view = renderRatingField()

    const node = getNode('rating')!

    const numberInput = view.getByLabelText('How would you rate Zammad?')

    expect(numberInput).toHaveAttribute('min', '1')
    expect(numberInput).toHaveAttribute('max', '5')

    const value = star.toString()

    await view.events.type(numberInput, value)

    waitFor(() => {
      expect(node.context?.value).toBe(value)
      expect(numberInput).toHaveValue(value)
    })
  })
})
