<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onClickOutside, onKeyStroke, useElementBounding, useWindowSize } from '@vueuse/core'
import { omit } from 'lodash-es'
import { computed, ref, toRef, useTemplateRef, watch } from 'vue'

import type {
  SegmentKind,
  YearWindow,
} from '#shared/components/Form/fields/FieldDate/dateFormat.ts'
import type { DateFieldContext } from '#shared/components/Form/fields/FieldDate/types.ts'
import { isDayDisabled } from '#shared/components/Form/fields/FieldDate/useCalendar.ts'
import { useDateFieldValue } from '#shared/components/Form/fields/FieldDate/useDateFieldValue.ts'
import { useDatePanel } from '#shared/components/Form/fields/FieldDate/useDatePanel.ts'
import { useSegmentedDateInput } from '#shared/components/Form/fields/FieldDate/useSegmentedDateInput.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { i18n } from '#shared/i18n.ts'
import stopEvent from '#shared/utils/events.ts'

import { useAnnouncer } from '#desktop/composables/accessibility/useAnnouncer.ts'

import FieldDatePanel from './FieldDatePanel.vue'

interface Props {
  context: DateFieldContext
}

const props = defineProps<Props>()

const contextReactive = toRef(props, 'context')

const {
  bounds,
  clearValue,
  commit,
  dateFnsLocale,
  hasValue,
  is24,
  localValue,
  localeFormat,
  refreshNow,
  selectedDate,
  showWeekNumbers,
  timePicker,
} = useDateFieldValue(contextReactive)

const editable = computed(() => !contextReactive.value.disabled)

const inputElement = useTemplateRef<HTMLInputElement>('input')

const yearWindow = computed<YearWindow>(() => {
  const { futureOnly, pastOnly } = contextReactive.value

  if (futureOnly && !pastOnly) return 'future'
  if (pastOnly && !futureOnly) return 'past'

  return 'around'
})

const { announce } = useAnnouncer()

const segmented = useSegmentedDateInput({
  el: inputElement,
  format: localeFormat,
  editable,
  yearWindow,
  defaultTime: computed(() => contextReactive.value.defaultTime),
  // A typed day the calendar would refuse is refused as well; the time within an allowed day
  // is clamped by `commit`, like a picked one.
  isAllowed: (date) => {
    refreshNow()

    return !isDayDisabled(date, bounds.value)
  },
  onApply: (date) => {
    if (date) {
      commit(date)
    } else if (hasValue.value) {
      localValue.value = null
    }
  },
  onEmptied: () => announce(i18n.t('The entry was not a valid date and has been cleared.')),
})

// The time groups are named like the inputs of the time panel.
const SEGMENT_NAMES: Record<SegmentKind, string> = {
  day: __('Day'),
  month: __('Month'),
  year: __('Year'),
  hour: __('Hours'),
  minute: __('Minutes'),
  second: __('Seconds'),
  meridiem: __('AM/PM'),
}

const activeSegmentName = computed(() => {
  const kind = segmented.activeSegment.value?.kind

  return kind ? i18n.t(SEGMENT_NAMES[kind]) : undefined
})

// One text input stands for every group, so it is the spinbutton of the group being edited:
// its name ends with the group, its value is the group's one. The name is composed from
// elements rather than written into `aria-label`, so the field is still found by its label alone.
const segmentNameId = computed(() => `${contextReactive.value.id}-segment`)
const attrsLabelId = computed(() => `${contextReactive.value.id}-name`)

// A picker without a label of its own, one bound of a range say, is named by its `aria-label`.
const attrsLabel = computed(() => {
  const label = contextReactive.value.attrs?.['aria-label']

  return typeof label === 'string' && !contextReactive.value.label ? label : undefined
})

const inputAttrs = computed(() => omit(contextReactive.value.attrs, 'aria-label'))

const inputLabelledBy = computed(() => {
  const ids: string[] = []

  if (contextReactive.value.label) ids.push(`label-${contextReactive.value.id}`)
  else if (attrsLabel.value) ids.push(attrsLabelId.value)

  ids.push(segmentNameId.value)

  return ids.join(' ')
})

const activeSegmentValueText = computed(() => {
  const segment = segmented.activeSegment.value

  if (!segment) return undefined

  return segment.value === null ? i18n.t('not set') : segment.text
})

// A screen reader hears the name of the field once, on entering it. The group being edited and
// its value are announced whenever a keystroke, a paste, a click or a value written while the
// field has the focus (a clamped time, a day picked in the panel alongside) changed either.
const announceSegmentChange = <T extends unknown[]>(handler: (...args: T) => void) => {
  const announcement = () =>
    activeSegmentName.value && `${activeSegmentName.value}, ${activeSegmentValueText.value}`

  return (...args: T) => {
    const before = announcement()

    handler(...args)

    const after = announcement()
    if (segmented.focused.value && after && after !== before) announce(after)
  }
}

watch(
  selectedDate,
  announceSegmentChange((date) => segmented.setDate(date)),
  { immediate: true },
)

const isModal = ref(false)

const panelId = computed(() => `${contextReactive.value.id}-panel`)

const wrapperElement = useTemplateRef('wrapper')
const panelElement = useTemplateRef('panel')
const panelComponent = useTemplateRef('panel-content')

useTrapTab(panelElement)

const ownerBounds = useElementBounding(wrapperElement)
const panelBounds = useElementBounding(panelElement)
const { height: windowHeight, width: windowWidth } = useWindowSize()

const VIEWPORT_MARGIN = 8
const OWNER_OFFSET = 4

const opensUpwards = computed(() => ownerBounds.y.value > windowHeight.value / 2)

const panelStyle = computed(() => {
  const left = Math.max(
    VIEWPORT_MARGIN,
    Math.min(ownerBounds.left.value, windowWidth.value - panelBounds.width.value - VIEWPORT_MARGIN),
  )

  const style: Record<string, string> = { left: `${left}px` }

  if (opensUpwards.value) {
    style.bottom = `${windowHeight.value - ownerBounds.top.value + OWNER_OFFSET}px`
  } else {
    style.top = `${ownerBounds.bottom.value + OWNER_OFFSET}px`
  }

  return style
})

let stopClickOutside: (() => void) | undefined

const {
  close,
  isOpen,
  open: openPanel,
} = useDatePanel({
  input: inputElement,
  disabled: () => Boolean(contextReactive.value.disabled),
  onOpen: () => {
    refreshNow()
    ownerBounds.update()
  },
  onOpened: () => {
    if (isModal.value) panelComponent.value?.focusActive()
    stopClickOutside = onClickOutside(panelElement, () => close(), {
      ignore: [wrapperElement],
    })
  },
  onClose: () => {
    stopClickOutside?.()
    stopClickOutside = undefined
  },
})

// Without `focusPanel` the input keeps the focus, so typing into the groups and picking in the
// panel can be mixed. Tab is not trapped and the panel is not modal then: the focus never enters
// the panel.
const open = ({ focusPanel = true } = {}) => {
  if (isOpen.value) return

  isModal.value = focusPanel
  openPanel()
}

// The panel shown alongside the input follows the group being edited: a time group brings up
// the time panel, a date group the calendar.
watch(
  () => segmented.activeSegment.value?.kind,
  (kind) => {
    if (isOpen.value && kind) panelComponent.value?.showPanelFor(kind)
  },
)

const toggle = () => {
  if (isOpen.value) close({ refocus: true })
  else open()
}

onKeyStroke(
  'Escape',
  (event) => {
    stopEvent(event)
    close({ refocus: true })
  },
  { target: panelElement },
)

const onInputKeydown = announceSegmentChange((event: KeyboardEvent) => {
  if (event.key === 'Escape') {
    if (!isOpen.value) return
    stopEvent(event)
    close({ refocus: true })
    return
  }

  if (event.key === 'Enter' || (event.key === 'ArrowDown' && event.altKey)) {
    stopEvent(event)
    open()
    return
  }

  segmented.onKeydown(event)
})

const onInputBeforeInput = announceSegmentChange(segmented.onBeforeInput)
const onInputPaste = announceSegmentChange(segmented.onPaste)

const groupsElement = useTemplateRef('groups')

const isOverGroups = (event: MouseEvent) => {
  const groups = groupsElement.value?.getBoundingClientRect()

  return !groups?.width || event.clientX <= groups.right
}

// The text ends well before the icon. A click in the blank part behind it starts at the first
// group and shows the panel alongside, rather than selecting the last group from far away.
const onInputClick = announceSegmentChange((event: MouseEvent) => {
  if (segmented.hasManualSelection()) return

  if (isOverGroups(event)) {
    segmented.onClick()
    return
  }

  segmented.selectFirst()
  open({ focusPanel: false })
})

const onInputBlur = (event: FocusEvent) => {
  segmented.onBlur()
  contextReactive.value.handlers.blur(event)
}

// The panel shown alongside the input goes once the focus leaves the field for good.
const onFieldFocusout = (event: FocusEvent) => {
  const target = event.relatedTarget as Node | null

  if (target && !wrapperElement.value?.contains(target) && !panelElement.value?.contains(target)) {
    close()
  }
}

const openButtonIcon = computed(() => (timePicker.value ? 'calendar-date-time' : 'calendar-event'))

const openButtonLabel = computed(() => {
  if (hasValue.value && segmented.text.value) {
    return `${i18n.t('Change date')}, ${segmented.text.value}`
  }

  return i18n.t('Choose date')
})

const iconClasses =
  'me-2.5 shrink-0 fill-stone-200 hover:fill-black focus-visible:rounded-xs focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:fill-neutral-500 dark:hover:fill-white'
</script>

<template>
  <!-- eslint-disable vuejs-accessibility/no-static-element-interactions -->
  <div
    ref="wrapper"
    class="relative flex w-full items-center"
    data-test-id="field-date"
    @focusout="onFieldFocusout"
  >
    <!-- The groups are painted by the layer below, the input keeps the caret and the selection. -->
    <input
      :id="context.id"
      ref="input"
      :name="context.node.name"
      :class="[context.classes.input, 'grow text-transparent caret-black dark:caret-white']"
      type="text"
      role="spinbutton"
      autocomplete="off"
      spellcheck="false"
      :disabled="context.disabled"
      :aria-labelledby="inputLabelledBy"
      :aria-describedby="context.describedBy"
      :aria-valuemin="segmented.activeSegment.value?.min"
      :aria-valuemax="segmented.activeSegment.value?.max"
      :aria-valuenow="segmented.activeSegment.value?.valueNow"
      :aria-valuetext="activeSegmentValueText"
      inputmode="numeric"
      aria-haspopup="dialog"
      :aria-controls="isOpen ? panelId : undefined"
      v-bind="inputAttrs"
      @keydown="onInputKeydown"
      @beforeinput="onInputBeforeInput"
      @paste="onInputPaste"
      @mousedown="segmented.onMousedown"
      @click="onInputClick"
      @focus="segmented.onFocus"
      @blur="onInputBlur"
    />
    <span v-if="attrsLabel" :id="attrsLabelId" class="sr-only">{{ attrsLabel }}</span>
    <span :id="segmentNameId" class="sr-only">{{ activeSegmentName }}</span>
    <span
      v-if="segmented.text.value"
      ref="groups"
      class="pointer-events-none absolute inset-y-0 inset-s-0 flex items-center overflow-hidden px-2.5 whitespace-pre text-contrast"
      aria-hidden="true"
      data-test-id="field-date-groups"
    >
      <span
        v-for="(part, index) in segmented.displayParts.value"
        :key="index"
        :class="{ 'text-stone-200 dark:text-neutral-500': !part.filled }"
        >{{ part.text }}</span
      >
    </span>
    <CommonIcon
      v-if="context.clearable && hasValue && !context.disabled"
      v-tooltip="$t('Clear the value')"
      :class="iconClasses"
      name="x-lg"
      size="xs"
      tabindex="0"
      role="button"
      @click.stop="clearValue()"
      @keydown.enter.prevent="clearValue()"
      @keydown.space.prevent="clearValue()"
    />
    <CommonIcon
      v-tooltip="openButtonLabel"
      :class="iconClasses"
      :name="openButtonIcon"
      size="tiny"
      tabindex="0"
      role="button"
      aria-haspopup="dialog"
      :aria-expanded="isOpen"
      @click.stop="toggle()"
      @keydown.enter.prevent="toggle()"
      @keydown.space.prevent="toggle()"
    />
    <Teleport to="body">
      <div
        v-if="isOpen"
        :id="panelId"
        ref="panel"
        role="dialog"
        :aria-modal="isModal || undefined"
        :aria-label="$t('Choose date')"
        class="fixed z-50 min-w-68 rounded-lg border border-neutral-100 bg-neutral-50 antialiased dark:border-gray-900 dark:bg-gray-500"
        :style="panelStyle"
        data-test-id="field-date-panel"
      >
        <FieldDatePanel
          ref="panel-content"
          :selected="selectedDate"
          :bounds="bounds"
          :with-time="timePicker"
          :default-time="context.defaultTime"
          :week-start="context.weekStart ?? 1"
          :locale="dateFnsLocale"
          :is24="is24"
          :show-week-numbers="showWeekNumbers"
          @commit="commit"
          @done="close({ refocus: true })"
        />
      </div>
    </Teleport>
  </div>
</template>
