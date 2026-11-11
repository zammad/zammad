// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { format as formatDate, isValid, parse, parseISO } from 'date-fns'
import { computed, ref, watch, type Ref } from 'vue'

import {
  buildFormatParts,
  completeYear,
  TIME_KINDS,
  toDateFnsFormat,
  type SegmentKind,
  type SegmentSpec,
  type YearWindow,
} from './dateFormat.ts'
import { DEFAULT_TIME } from './useCalendar.ts'

import type { TimeOfDay } from './types.ts'

export interface UseSegmentedDateInputOptions {
  el: Ref<HTMLInputElement | null>
  // The locale's format in Zammad's own tokens, e.g. `dd.mm.yyyy HH:MM` or `mm/dd/yyyy l:MM P`.
  format: Ref<string>
  editable: Ref<boolean>
  // Where a year typed with two digits lands, see `expandYear`.
  yearWindow?: Ref<YearWindow>
  // The time a complete date without one gets once the field is left, see `DEFAULT_TIME`.
  defaultTime?: Ref<TimeOfDay | undefined>
  // Called with the date once every group is filled and the whole forms a real date, and with
  // `null` once every group is cleared. A partial or impossible entry leaves the value alone.
  // Returns the date stored when it differs from the one applied, a date kept inside the bounds.
  onApply: (date: Date | null) => Date | void
  // Refuses a complete date, one outside the bounds say. It counts as impossible then: it is
  // not applied, and leaving the field empties it unless it is the value the field was given.
  isAllowed?: (date: Date) => boolean
  // Called once leaving the field has thrown a partial or impossible entry away.
  onEmptied?: () => void
}

const MERIDIEMS = ['am', 'pm']

const DATE_KINDS = new Set<SegmentKind>(['year', 'month', 'day'])

const defaultTimeValue = (spec: SegmentSpec, time: TimeOfDay) => {
  if (!TIME_KINDS.has(spec.kind)) return null

  return formatDate(new Date(2000, 0, 1, time.hours, time.minutes), spec.token)
}

const wrap = (value: number, min: number, max: number) => {
  if (value > max) return min
  if (value < min) return max
  return value
}

export const useSegmentedDateInput = (options: UseSegmentedDateInputOptions) => {
  const parts = computed(() => buildFormatParts(options.format.value))

  const segments = computed(() =>
    parts.value.flatMap((part) => (part.type === 'segment' ? [part.spec] : [])),
  )

  const dateFnsFormat = computed(() => toDateFnsFormat(parts.value))

  const values = ref<(string | null)[]>(segments.value.map(() => null))

  // The date the groups last agreed on, so a changed format (a switched locale) rewrites the
  // groups instead of emptying them.
  let current: Date | undefined

  // The date the edits since the focus led to. A date set from outside drops it, so leaving the
  // field keeps that date as it is, like one only visited.
  let edited: Date | undefined

  const fill = (date: Date | undefined) => {
    values.value = segments.value.map((spec) => (date ? formatDate(date, spec.token) : null))
  }

  watch(segments, () => fill(current))

  const activeIndex = ref(0)

  const focused = ref(false)

  // The digits typed into the active group since it was entered, so the first digit replaces
  // what the group showed before.
  let typed = ''

  // The focus came from a pointer, so the click that follows picks the group.
  let pointerFocus = false

  const display = (index: number) => {
    const spec = segments.value[index]
    const value = values.value[index]

    if (value === null) return spec.placeholder
    if (spec.kind === 'meridiem') return value

    return value.padStart(spec.length, '0')
  }

  const fullText = computed(() =>
    parts.value.map((part) => (part.type === 'literal' ? part.text : display(part.index))).join(''),
  )

  // The text split into its groups and literals, for a rendering that mutes what has no value
  // yet: a group showing its placeholder, and a literal next to such a group.
  const displayParts = computed(() => {
    const filledAt = (position: number) => {
      const part = parts.value[position]
      return !part || part.type === 'literal' || values.value[part.index] !== null
    }

    return parts.value.map((part, position) =>
      part.type === 'literal'
        ? { text: part.text, filled: filledAt(position - 1) && filledAt(position + 1) }
        : { text: display(part.index), filled: filledAt(position) },
    )
  })

  const valueNow = (spec: SegmentSpec, value: string | null) => {
    if (value === null) return undefined
    if (spec.kind === 'meridiem') return MERIDIEMS.indexOf(value)

    return Number(value)
  }

  // What a screen reader is told about the group being edited.
  const activeSegment = computed(() => {
    const spec = segments.value[activeIndex.value]
    if (!spec) return undefined

    const value = values.value[activeIndex.value]

    return {
      kind: spec.kind,
      min: spec.min,
      max: spec.max,
      value,
      valueNow: valueNow(spec, value),
      text: display(activeIndex.value),
    }
  })

  const isEmpty = computed(() => values.value.every((value) => value === null))

  const isComplete = computed(() => values.value.every((value) => value !== null))

  const text = fullText

  const ranges = computed(() => {
    const result: { start: number; end: number }[] = []
    let offset = 0

    parts.value.forEach((part) => {
      const length = part.type === 'literal' ? part.text.length : display(part.index).length

      if (part.type === 'segment') result.push({ start: offset, end: offset + length })

      offset += length
    })

    return result
  })

  const lastIndex = computed(() => segments.value.length - 1)

  const parseText = () => {
    if (!isComplete.value) return undefined

    const date = parse(fullText.value, dateFnsFormat.value, new Date())

    return isValid(date) ? date : undefined
  }

  const allowedDate = () => {
    const date = parseText()

    if (!date || (options.isAllowed && !options.isAllowed(date))) return undefined

    return date
  }

  // Compared group by group, as a value can carry more precision (seconds) than the groups show.
  const showsCurrent = () => {
    const date = current
    if (!date) return false

    return segments.value.every(
      (spec, index) => values.value[index] === formatDate(date, spec.token),
    )
  }

  const isSameShown = (date: Date, other: Date) =>
    segments.value.every((spec) => formatDate(date, spec.token) === formatDate(other, spec.token))

  const hasFocus = () => Boolean(options.el.value && document.activeElement === options.el.value)

  const selectActive = () => {
    const range = ranges.value[activeIndex.value]

    if (!range || !hasFocus()) return

    options.el.value?.setSelectionRange(range.start, range.end)
  }

  const syncElement = () => {
    const element = options.el.value
    if (!element) return

    if (element.value !== text.value) element.value = text.value

    selectActive()
  }

  watch([text, options.el], syncElement, { flush: 'sync', immediate: true })

  const apply = () => {
    if (isEmpty.value) {
      current = undefined
      options.onApply(null)
      return
    }

    const date = allowedDate()

    if (!date) return

    current = date

    const stored = options.onApply(date) ?? date

    // The bounds may move the date onto the value already stored, which brings no `setDate`. The
    // groups follow once the field is left, so a later group (the half of the day) still applies
    // to the hour typed.
    if (stored !== date && !focused.value) fill(stored)

    current = stored
    edited = stored
  }

  // Leaving a group completes what was typed into it so far and applies it.
  const finishPendingGroup = () => {
    if (typed === '') return false

    const spec = segments.value[activeIndex.value]

    values.value[activeIndex.value] = completeYear(spec, typed, options.yearWindow?.value)

    typed = ''

    return true
  }

  const activate = (index: number) => {
    const pending = finishPendingGroup()

    activeIndex.value = Math.min(Math.max(index, 0), lastIndex.value)
    selectActive()

    if (pending) apply()
  }

  const setDate = (date: Date | undefined) => {
    current = date

    if (!date || !edited || !isSameShown(date, edited)) edited = undefined

    if (!date) {
      if (!isEmpty.value) fill(undefined)
      return
    }

    const shown = parseText()
    if (shown && shown.getTime() === date.getTime()) return

    fill(date)
    typed = ''
  }

  const advance = () => {
    finishPendingGroup()

    if (activeIndex.value < lastIndex.value) activeIndex.value += 1

    selectActive()
    apply()
  }

  // A group applies once it cannot take another digit; until then the value waits, so a
  // half-typed `1` of `12` does not pass as the first of the month.
  const inputDigit = (digit: string) => {
    const index = activeIndex.value
    const spec = segments.value[index]

    if (spec.kind === 'meridiem') return

    let candidate = typed + digit
    if (Number(candidate) > spec.max) candidate = digit

    values.value[index] = candidate
    typed = candidate

    if (candidate.length >= spec.length || Number(candidate) * 10 > spec.max) advance()
    else selectActive()
  }

  const inputMeridiem = (letter: string) => {
    values.value[activeIndex.value] = letter.toLowerCase() === 'p' ? 'pm' : 'am'
    advance()
  }

  const inputCharacter = (character: string) => {
    const spec = segments.value[activeIndex.value]

    if (/\d/.test(character)) {
      inputDigit(character)
    } else if (spec.kind === 'meridiem' && /[ap]/i.test(character)) {
      inputMeridiem(character)
    } else if (typed && !/[a-z0-9]/i.test(character)) {
      // A typed separator finishes the group, like in the native date input.
      advance()
    }
  }

  const clearActive = () => {
    values.value[activeIndex.value] = null
    typed = ''
    selectActive()
    apply()
  }

  const step = (delta: 1 | -1) => {
    finishPendingGroup()

    const index = activeIndex.value
    const spec = segments.value[index]
    const value = values.value[index]

    if (spec.kind === 'meridiem') {
      values.value[index] = value === MERIDIEMS[0] ? MERIDIEMS[1] : MERIDIEMS[0]
    } else if (value === null && spec.kind === 'year') {
      // Like in the native date input, an empty year starts at the current one.
      values.value[index] = formatDate(new Date(), spec.token)
    } else if (value === null) {
      values.value[index] = String(delta > 0 ? spec.min : spec.max)
    } else if (spec.kind === 'year') {
      values.value[index] = String(Math.min(Math.max(Number(value) + delta, spec.min), spec.max))
    } else {
      values.value[index] = String(wrap(Number(value) + delta, spec.min, spec.max))
    }

    typed = ''
    selectActive()
    apply()
  }

  const fillFromText = (pasted: string) => {
    // date-fns reads a short year for `yyyy` literally, as year 26 say, so a pasted short year
    // goes through the groups below to be completed like a typed one.
    const direct = [parse(pasted, dateFnsFormat.value, new Date()), parseISO(pasted)].find(
      (date) => isValid(date) && date.getFullYear() >= 100,
    )

    if (direct) {
      values.value = segments.value.map((spec) => formatDate(direct, spec.token))
      return
    }

    const numbers = pasted.match(/\d+/g) ?? []
    const meridiem = pasted.match(/am|pm/i)?.[0].toLowerCase()
    let position = 0

    values.value = segments.value.map((spec) => {
      if (spec.kind === 'meridiem') return meridiem ?? null

      const number = numbers[position]
      position += 1

      if (number === undefined) return null

      return completeYear(spec, number, options.yearWindow?.value)
    })
  }

  const segmentAt = (caret: number) => {
    const index = ranges.value.findIndex((range, position) => {
      const next = ranges.value[position + 1]
      return caret <= range.end || !next || caret < next.start
    })

    return index === -1 ? lastIndex.value : index
  }

  // The selection may have been moved by the browser or a script since the group was entered.
  const syncActiveFromSelection = () => {
    const caret = options.el.value?.selectionStart
    const range = ranges.value[activeIndex.value]

    if (caret == null || !range || (caret >= range.start && caret <= range.end)) return

    activate(segmentAt(caret))
  }

  const onKeydown = (event: KeyboardEvent) => {
    if (!options.editable.value) return

    syncActiveFromSelection()

    switch (event.key) {
      case 'ArrowLeft':
        activate(activeIndex.value - 1)
        break
      case 'ArrowRight':
        activate(activeIndex.value + 1)
        break
      case 'ArrowUp':
        step(1)
        break
      case 'ArrowDown':
        step(-1)
        break
      case 'Home':
        activate(0)
        break
      case 'End':
        activate(lastIndex.value)
        break
      case 'Backspace':
      case 'Delete':
        clearActive()
        break
      case 'Tab': {
        const target = activeIndex.value + (event.shiftKey ? -1 : 1)
        if (target < 0 || target > lastIndex.value) return
        activate(target)
        break
      }
      default:
        return
    }

    event.preventDefault()
  }

  // The browser never edits the text itself, every change goes through the groups.
  const onBeforeInput = (event: InputEvent) => {
    event.preventDefault()

    if (!options.editable.value) return

    syncActiveFromSelection()

    if (event.inputType === 'insertText' && event.data) {
      Array.from(event.data).forEach(inputCharacter)
    } else if (
      event.inputType === 'deleteContentBackward' ||
      event.inputType === 'deleteContentForward'
    ) {
      clearActive()
    }
  }

  const onPaste = (event: ClipboardEvent) => {
    event.preventDefault()

    if (!options.editable.value) return

    const pasted = event.clipboardData?.getData('text').trim()
    if (!pasted) return

    fillFromText(pasted)
    typed = ''
    selectActive()
    apply()
  }

  const onMousedown = () => {
    pointerFocus = true
  }

  // Keyboard focus enters at the first group, or at the last one when it arrives backwards
  // (Shift+Tab). The browser selects the whole text right after the focus event, so the group
  // is selected once that has happened.
  const onFocus = (event: FocusEvent) => {
    focused.value = true
    edited = undefined

    if (pointerFocus) return

    const element = options.el.value
    const related = event.relatedTarget as Node | null
    const backwards = Boolean(
      element &&
      related &&
      element.compareDocumentPosition(related) & Node.DOCUMENT_POSITION_FOLLOWING,
    )

    queueMicrotask(() => {
      if (hasFocus()) activate(backwards ? lastIndex.value : 0)
    })
  }

  const hasManualSelection = () => {
    const element = options.el.value

    return Boolean(element && element.selectionStart !== element.selectionEnd)
  }

  // A stretch selected by hand, with a drag or a double click, stays as it is so it can be
  // copied. Only a click on a group enters it.
  const onClick = () => {
    pointerFocus = false

    if (hasManualSelection()) return

    activate(segmentAt(options.el.value?.selectionStart ?? 0))
  }

  const selectFirst = () => {
    pointerFocus = false

    activate(0)
  }

  // A date without a time starts in the morning, like in the legacy UI.
  const fillDefaultTime = () => {
    const specs = segments.value

    const dateComplete = specs.every(
      (spec, index) => !DATE_KINDS.has(spec.kind) || values.value[index] !== null,
    )

    if (!dateComplete) return

    values.value = values.value.map(
      (value, index) =>
        value ?? defaultTimeValue(specs[index], options.defaultTime?.value ?? DEFAULT_TIME),
    )
  }

  // Once the field is left, only a real date may stay behind: a partial or impossible entry
  // empties the field, so neither it nor the value before it reaches the form.
  const settle = () => {
    // A value only visited, not edited, stays as it is even outside the bounds, so an expired
    // pending time is neither moved up to now nor emptied.
    if (!edited && showsCurrent()) return

    fillDefaultTime()

    if (isEmpty.value || allowedDate()) {
      apply()
      return
    }

    current = undefined
    fill(undefined)
    options.onApply(null)
    options.onEmptied?.()
  }

  const onBlur = () => {
    focused.value = false
    pointerFocus = false

    finishPendingGroup()
    settle()
  }

  return {
    activeSegment,
    displayParts,
    focused,
    text,
    setDate,
    onBeforeInput,
    onBlur,
    onClick,
    onFocus,
    onKeydown,
    onMousedown,
    onPaste,
    hasManualSelection,
    selectFirst,
  }
}
