// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, nextTick, ref, watch, type Ref } from 'vue'

import {
  enterDigit,
  wrap,
  type SegmentSpec,
} from '#shared/components/Form/fields/FieldDate/dateFormat.ts'
import { padTime } from '#shared/components/Form/fields/FieldDate/useCalendarPanel.ts'

export interface UseTimeFieldEntryOptions {
  el: Ref<HTMLInputElement | null>
  spec: Ref<SegmentSpec>
  // The applied value, as the field shows it.
  display: Ref<string>
  apply: (value: number) => void
  // Called once a typed value is complete and applied.
  onComplete?: () => void
  // Arrow left and right, to the field before or after this one.
  onMove?: (direction: 1 | -1) => void
}

// One input of the time panel, edited like a group of the segmented input above it: its value is
// selected whenever the field is entered or changed, so the first digit typed replaces it.
export const useTimeFieldEntry = (options: UseTimeFieldEntryOptions) => {
  const draft = ref(options.display.value)

  const valueNow = computed(() => (draft.value === '' ? undefined : Number(draft.value)))

  // The digits typed since the field was entered or last applied.
  let typed = ''

  // The focus came from a pointer, so the click that follows selects the value.
  let pointerFocus = false

  const hasFocus = () => Boolean(options.el.value && document.activeElement === options.el.value)

  const select = () => {
    const element = options.el.value
    if (!element || !hasFocus()) return

    element.setSelectionRange(0, element.value.length)
  }

  // Setting the value of the element drops its selection.
  watch(draft, () => nextTick(select))

  watch(options.display, (value) => {
    if (typed === '') draft.value = value
  })

  // The applied time can be moved by the bounds, so the field shows what was stored.
  const applyValue = (value: number) => {
    options.apply(value)
    draft.value = padTime(value)

    nextTick(() => {
      if (typed === '') draft.value = options.display.value
      select()
    })
  }

  // Completes what was typed so far; an impossible or emptied value snaps back to the applied one.
  const finish = () => {
    const entry = typed
    typed = ''

    const value = Number(entry)
    const { min, max } = options.spec.value

    if (entry === '' || value < min || value > max) {
      draft.value = options.display.value
      select()
      return false
    }

    applyValue(value)
    return true
  }

  const inputDigit = (digit: string) => {
    const { entry, complete } = enterDigit(options.spec.value, typed, digit)

    typed = entry
    draft.value = padTime(Number(entry))

    if (!complete) {
      select()
      return false
    }

    if (finish()) options.onComplete?.()

    return true
  }

  // A typed separator completes the entry, like in a group of the segmented input.
  const inputCharacter = (character: string) => {
    if (/\d/.test(character)) return inputDigit(character)
    if (typed === '' || /[a-z]/i.test(character)) return false

    if (finish()) options.onComplete?.()

    return true
  }

  // Once a value is complete the focus may have moved on, so the rest of the text is dropped.
  const inputText = (text: string) => {
    Array.from(text).some(inputCharacter)
  }

  const step = (delta: 1 | -1) => {
    if (typed !== '') finish()

    const { min, max } = options.spec.value
    const current = draft.value === '' ? null : Number(draft.value)

    let next: number
    if (current === null) next = delta > 0 ? min : max
    else next = wrap(current + delta, min, max)

    applyValue(next)
  }

  const move = (direction: 1 | -1) => {
    if (typed !== '') finish()

    options.onMove?.(direction)
    select()
  }

  const onKeydown = (event: KeyboardEvent) => {
    switch (event.key) {
      case 'ArrowUp':
        step(1)
        break
      case 'ArrowDown':
        step(-1)
        break
      case 'ArrowLeft':
        move(-1)
        break
      case 'ArrowRight':
        move(1)
        break
      default:
        return
    }

    event.preventDefault()
  }

  // The browser never edits the text itself, every change goes through the digits.
  const onBeforeInput = (event: InputEvent) => {
    event.preventDefault()

    if (event.inputType === 'insertText' && event.data) {
      inputText(event.data)
    } else if (event.inputType.startsWith('delete')) {
      typed = ''
      draft.value = ''
    }
  }

  const onPaste = (event: ClipboardEvent) => {
    event.preventDefault()

    inputText(event.clipboardData?.getData('text') ?? '')
  }

  // A press inside the selection collapses it only after the click is over, so a press into the
  // focused field keeps the browser out of the selection altogether.
  const onMousedown = (event: MouseEvent) => {
    if (hasFocus()) {
      event.preventDefault()

      if (typed !== '') finish()
      else select()

      return
    }

    pointerFocus = true
  }

  // The browser places the caret after the focus event, so the value is selected once that has
  // happened, and only on the click that follows for a focus from a pointer.
  const onFocus = () => {
    if (pointerFocus) return

    queueMicrotask(select)
  }

  const onClick = () => {
    pointerFocus = false

    select()
  }

  const onBlur = () => {
    pointerFocus = false

    if (typed !== '' || draft.value === '') finish()
  }

  return {
    draft,
    finish,
    onBeforeInput,
    onBlur,
    onClick,
    onFocus,
    onKeydown,
    onMousedown,
    onPaste,
    valueNow,
  }
}
