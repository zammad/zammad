// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@shared/i18n'
import { renderComponent } from '@tests/support/components'
import { ref } from 'vue'
import CommonButtonPills from '../CommonButtonPills.vue'
import type { ButtonPillOption } from '../types'

describe('buttons component', () => {
  it('renders buttons', async () => {
    const options: ButtonPillOption[] = [
      {
        label: 'Button 1',
        value: '1',
      },
      {
        label: 'Button 2',
        value: '2',
      },
    ]

    const modelValue = ref('1')

    const view = renderComponent(CommonButtonPills, {
      props: {
        options,
      },
      vModel: {
        modelValue,
      },
    })

    const button1 = view.getByRole('button', { name: 'Button 1' })
    const button2 = view.getByRole('button', { name: 'Button 2' })

    expect(button1).toBeInTheDocument()
    expect(button2).toBeInTheDocument()

    expect(button1).toHaveClass('bg-gray-200')
    expect(button2).not.toHaveClass('bg-gray-200')
    expect(button2).toHaveClass('bg-gray-600')

    await view.events.click(button2)

    expect(button2).toHaveClass('bg-gray-200')
    expect(button1).not.toHaveClass('bg-gray-200')
    expect(button1).toHaveClass('bg-gray-600')

    expect(modelValue.value).toBe('2')
    expect(view.emitted()['update:modelValue']).toBeTruthy()
  })

  it('translates text', () => {
    i18n.setTranslationMap(new Map([['Button %s', 'Translated %s']]))

    const view = renderComponent(CommonButtonPills, {
      props: {
        options: [
          { label: 'Button %s', labelPlaceholder: ['text'], value: '1' },
        ],
        modelValue: '1',
      },
    })

    expect(view.getByText('Translated text')).toBeInTheDocument()
  })

  it('cannot select disabled option', async () => {
    const options: ButtonPillOption[] = [
      {
        label: 'Button 1',
        value: '1',
      },
      {
        label: 'Button 2',
        disabled: true,
        value: '2',
      },
    ]

    const modelValue = ref('1')

    const view = renderComponent(CommonButtonPills, {
      props: {
        options,
      },
      vModel: {
        modelValue,
      },
    })

    const button2 = view.getByRole('button', { name: 'Button 2' })

    expect(button2).toBeDisabled()

    await view.events.click(view.getByRole('button', { name: 'Button 2' }))

    expect(modelValue.value).toBe('1')
  })
})
