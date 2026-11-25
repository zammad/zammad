// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'
import { defineComponent, h, ref } from 'vue'

import { mountComponent } from '#tests/browser/utils.ts'

import { useKeyboardShortcutEventBus } from '#shared/composables/useKeyboardEventBus/useKeyboardEventBus.ts'
import { useKeyboardShortcut } from '#shared/composables/useKeyboardShortcut/useKeyboardShortcut.ts'

const recordingComponent = (register: (record: (name: string) => () => void) => void) =>
  defineComponent({
    setup() {
      const pressed = ref<string[]>([])

      register((name) => () => pressed.value.push(name))

      return () => [
        h('textarea', { 'aria-label': 'Text' }),
        h('output', { 'aria-label': 'Pressed' }, pressed.value.join(' ')),
      ]
    },
  })

// Real keydown events differ from synthetic ones in what `key` carries with modifiers held,
//   which the combination matching relies on.
it('matches shortcuts on real key presses', async () => {
  mountComponent(
    recordingComponent((record) =>
      ['h', 'shift+c', '?', 'shift+arrowdown', 'ctrl+enter'].forEach((combination) =>
        useKeyboardShortcutEventBus(combination, {
          key: combination,
          handler: record(combination),
        }),
      ),
    ),
  )

  const pressed = page.getByLabelText('Pressed')

  await userEvent.keyboard('h')
  await userEvent.keyboard('{Shift>}C{/Shift}')
  await userEvent.keyboard('{Shift>}?{/Shift}')
  await userEvent.keyboard('{Shift>}{ArrowDown}{/Shift}')
  await userEvent.keyboard('{Control>}{Enter}{/Control}')

  await expect.element(pressed).toHaveTextContent('h shift+c ? shift+arrowdown ctrl+enter')
})

it('leaves modifier-less shortcuts to a focused text field', async () => {
  mountComponent(
    recordingComponent((record) => {
      useKeyboardShortcut('dashboard', record('h'), { onlyOutsideInputs: true })
      useKeyboardShortcut('update-as-closed', record('shift+c'), { onlyOutsideInputs: true })
      useKeyboardShortcut('submit-form', record('ctrl+enter'))
    }),
  )

  const text = page.getByLabelText('Text')

  await userEvent.click(text)
  await userEvent.keyboard('h{Shift>}C{/Shift}')
  await userEvent.keyboard('{Control>}{Enter}{/Control}')

  await expect.element(text).toHaveValue('hC')
  await expect.element(page.getByLabelText('Pressed')).toHaveTextContent('ctrl+enter')
})
