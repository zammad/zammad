<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { i18n } from '@shared/i18n'
import { useApplicationStore } from '@shared/stores/application'
import flatpickr from 'flatpickr'
import 'flatpickr/dist/themes/dark.css'
import {
  onBeforeUnmount,
  onMounted,
  ref,
  toRef,
  shallowRef,
  watch,
  watchEffect,
  computed,
  nextTick,
} from 'vue'
import { useEventListener } from '@vueuse/core'
import type { RouteLocationRaw } from 'vue-router'
import { useRawHTMLIcon } from '@shared/components/CommonIcon'
import testFlags from '@shared/utils/testFlags'
import type { FormFieldContext } from '../../types/field'
import useValue from '../../composables/useValue'

export interface Props {
  context: FormFieldContext<{
    futureOnly?: boolean
    maxDate?: flatpickr.Options.DateOption
    minDate?: flatpickr.Options.DateOption
    link?: RouteLocationRaw
  }>
}

const props = defineProps<Props>()

const { currentValue } = useValue(toRef(props, 'context'))

const application = useApplicationStore()

const locale: flatpickr.CustomLocale = {
  // calendar on desktop always starts at 1
  firstDayOfWeek: 1,
  weekdays: {
    shorthand: [
      i18n.t('Sun'),
      i18n.t('Mon'),
      i18n.t('Tue'),
      i18n.t('Wed'),
      i18n.t('Thu'),
      i18n.t('Fri'),
      i18n.t('Sat'),
    ],
    longhand: [
      i18n.t('Sunday'),
      i18n.t('Monday'),
      i18n.t('Tuesday'),
      i18n.t('Wednesday'),
      i18n.t('Thursday'),
      i18n.t('Friday'),
      i18n.t('Saturday'),
    ],
  },
  months: {
    shorthand: [
      i18n.t('Jan'),
      i18n.t('Feb'),
      i18n.t('Mar'),
      i18n.t('Apr'),
      i18n.t('May'),
      i18n.t('Jun'),
      i18n.t('Jul'),
      i18n.t('Aug'),
      i18n.t('Sep'),
      i18n.t('Oct'),
      i18n.t('Nov'),
      i18n.t('Dec'),
    ],
    longhand: [
      i18n.t('January'),
      i18n.t('February'),
      i18n.t('March'),
      i18n.t('April'),
      i18n.t('May'),
      i18n.t('June'),
      i18n.t('July'),
      i18n.t('August'),
      i18n.t('September'),
      i18n.t('October'),
      i18n.t('November'),
      i18n.t('December'),
    ],
  },
  rangeSeparator: i18n.t(' to '),
  weekAbbreviation: i18n.t('CW'),
}

const pickerNode = shallowRef<HTMLElement>()
const datepicker = shallowRef<flatpickr.Instance>()

const time = computed(() => {
  return props.context.type === 'datetime'
})

const getMinDate = () => {
  if (props.context.minDate) {
    return props.context.minDate
  }
  if (props.context.futureOnly) {
    const now = new Date()
    const tomorrow = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate() + 1,
    )
    return tomorrow
  }
  return undefined
}

const canSelectToday = (picker: flatpickr.Instance) => {
  const { minDate } = picker.config
  if (!minDate) return true
  const now = new Date()
  return now.getTime() >= minDate.getTime()
}

const createTodayButton = (picker: flatpickr.Instance) => {
  const todayAvailable = canSelectToday(picker)

  if (!todayAvailable) return null

  const todayButton = document.createElement('button')
  todayButton.addEventListener('click', () => {
    picker.setDate('today', true)
  })
  todayButton.type = 'button'
  todayButton.name = 'today'
  todayButton.textContent = i18n.t('Today')
  todayButton.className = 'flex-1 hover:bg-gray-300 border border-gray rounded'

  return todayButton
}

const createClearButton = (picker: flatpickr.Instance) => {
  const clearButton = document.createElement('button')
  clearButton.addEventListener('click', () => {
    picker.clear(true)
  })
  clearButton.type = 'button'
  clearButton.name = 'clear'
  clearButton.className = 'flex-1 hover:bg-gray-300 border border-gray rounded'
  clearButton.textContent = i18n.t('Clear')

  return clearButton
}

const createCalendarFooter = (picker: flatpickr.Instance) => {
  const footer = document.createElement('div')
  footer.className = 'flex p-2 gap-2'

  const clearButton = createClearButton(picker)
  const todayButton = createTodayButton(picker)

  footer.appendChild(clearButton)
  if (todayButton) footer.appendChild(todayButton)

  return footer
}

const iconPrevArrow = useRawHTMLIcon({ name: 'mobile-chevron-left' })
const iconNextArrow = useRawHTMLIcon({ name: 'mobile-chevron-right' })

const createFlatpickr = () => {
  if (!pickerNode.value || props.context.disabled) return undefined

  if (datepicker.value) {
    datepicker.value.destroy()
  }

  // TODO redesign month selection
  return flatpickr(pickerNode.value, {
    locale,
    disableMobile: true,
    inline: true,
    time_24hr: i18n.timeFormat() === '24hour',
    enableTime: time.value,
    allowInput: true,
    // append calendar to parent, so we can add our own elements after input
    // otherwise everything after input will actually appear after calendar
    appendTo: pickerNode.value.parentNode?.parentNode as HTMLElement,
    // The primary input element should display the current value of the input using context._value
    defaultDate: currentValue.value,
    maxDate: props.context.maxDate,
    minDate: getMinDate(),
    weekNumbers: application.config.datepicker_show_calendar_weeks === true,
    prevArrow: iconPrevArrow,
    nextArrow: iconNextArrow,
    animate: !VITE_TEST_MODE,
    formatDate(date) {
      const isoDate = date.toISOString()
      if (time.value) return i18n.dateTime(isoDate)
      return i18n.date(isoDate)
    },
    onChange([date]) {
      if (!date) {
        props.context.node.input(date)
        return
      }
      const formatted = flatpickr.formatDate(date, time.value ? 'Z' : 'Y-m-d')
      props.context.node.input(formatted)
    },
  })
}

// store calendar height to animate it's appearance later
let flatpickrHeight = 0
const recalculateHeight = async (
  flatpickr?: flatpickr.Instance,
): Promise<void> => {
  if (!flatpickr) return undefined
  const { calendarContainer } = flatpickr
  if (!calendarContainer) return undefined
  const { height } = calendarContainer.style
  calendarContainer.style.height = 'auto'
  return new Promise<void>((resolve) => {
    requestAnimationFrame(() => {
      flatpickrHeight =
        calendarContainer.clientHeight || calendarContainer.scrollHeight
      calendarContainer.style.height = height
      resolve()
    })
  })
}

const rerenderFlatpickr = async () => {
  const flatpickr = createFlatpickr()
  if (flatpickr) {
    const footer = createCalendarFooter(flatpickr)
    const calendarNode = flatpickr.calendarContainer
    calendarNode.setAttribute('role', 'dialog')
    calendarNode.setAttribute('aria-label', i18n.t('Calendar'))
    calendarNode.appendChild(footer)
    await recalculateHeight(flatpickr)
  }
  datepicker.value = flatpickr
}

onMounted(rerenderFlatpickr)

watch(time, (enable) => datepicker.value?.set('enableTime', enable))

// rerender flatpickr, if props dynamically change
const watchableProps = ['maxDate', 'minDate', 'disabled', 'futureOnly']

watch(
  watchableProps.map((name) => () => props.context[name]),
  rerenderFlatpickr,
)

watch(currentValue, (date: string) => {
  datepicker.value?.setDate(date, false)
})

watch(
  () => application.config.datepicker_show_calendar_weeks,
  rerenderFlatpickr,
)

// toggle calendar visibility when showPicker changes
const showPicker = ref(false)
watchEffect(async () => {
  if (!datepicker.value) return

  const calendar = datepicker.value.calendarContainer
  const clearButton = calendar.getElementsByTagName('button').namedItem('clear')
  const todayButton = calendar.getElementsByTagName('button').namedItem('today')

  if (!showPicker.value) {
    clearButton?.setAttribute('tabindex', '-1')
    todayButton?.setAttribute('tabindex', '-1')
    calendar.setAttribute('aria-hidden', 'true')
    calendar.style.height = '0px'

    nextTick(() => {
      testFlags.set(`field-date-time-${props.context.id}.closed`)
    })
  } else {
    if (!flatpickrHeight) {
      // if form was initially rendered as hidden, the height will be 0
      await recalculateHeight(datepicker.value)
    }
    calendar.style.height = `${flatpickrHeight}px`
    calendar.removeAttribute('aria-hidden')
    clearButton?.removeAttribute('tabindex')
    todayButton?.removeAttribute('tabindex')

    nextTick(() => {
      testFlags.set(`field-date-time-${props.context.id}.opened`)
    })
  }
})

// hide calendar, if clicked outside of calendar or input
useEventListener('click', (e) => {
  const { target } = e

  if (!target || !datepicker.value || !showPicker.value || !pickerNode.value)
    return

  const calendarNode = datepicker.value.calendarContainer

  const outsideOfCalendar = !calendarNode.contains(target as Node)
  const outsideOfInput = !pickerNode.value.contains(target as Node)

  if (outsideOfCalendar && outsideOfInput) {
    showPicker.value = false
  }
})

onBeforeUnmount(() => {
  datepicker.value?.destroy?.()
})
</script>

<template>
  <!-- TODO add placeholder support when styling will be finished -->
  <div class="flex w-full ltr:pr-3 rtl:pl-3">
    <input
      :id="props.context.id"
      ref="pickerNode"
      :name="props.context.node.name"
      :class="props.context.classes.input"
      :disabled="(props.context.disabled as boolean)"
      @blur="context.handlers.blur"
      @focus="showPicker = true"
    />
  </div>
  <div v-show="showPicker" class="mx-2 w-full">
    <div class="h-[1px] w-full bg-white/10"></div>
  </div>
</template>

<style>
.flatpickr-calendar,
.flatpickr-current-month .flatpickr-monthDropdown-months,
.flatpickr-months .flatpickr-month,
span.flatpickr-weekday {
  @apply bg-transparent;
}

.flatpickr-calendar {
  box-shadow: none;
  overflow: hidden;
}

.flatpickr-calendar.animate {
  transition: height 0.5s;
}

.flatpickr-calendar:not([aria-hidden]) {
  @apply mb-2;
}

span.flatpickr-weekday {
  @apply font-light uppercase;
}

.flatpickr-day.selected:hover,
.flatpickr-day.selected {
  background: none;
  @apply border-blue bg-blue;
}

.flatpickr-months .flatpickr-prev-month.flatpickr-prev-month:hover,
.flatpickr-months .flatpickr-prev-month.flatpickr-prev-month {
  left: unset;
  @apply right-8 w-auto p-2;
}

.flatpickr-months .flatpickr-next-month.flatpickr-next-month:hover,
.flatpickr-months .flatpickr-next-month.flatpickr-next-month {
  @apply w-auto p-2;
}

.flatpickr-months .flatpickr-prev-month:hover,
.flatpickr-months .flatpickr-next-month:hover,
.flatpickr-months .flatpickr-next-month,
.flatpickr-months .flatpickr-prev-month {
  @apply text-blue;
}

.flatpickr-months .flatpickr-prev-month:hover svg,
.flatpickr-months .flatpickr-next-month:hover svg {
  @apply fill-current;
}

.flatpickr-months .flatpickr-prev-month svg,
.flatpickr-months .flatpickr-next-month svg {
  @apply h-5 w-5;
}

.flatpickr-months .flatpickr-current-month {
  left: 5px;
  @apply text-left text-sm;
}

.flatpickr-current-month .flatpickr-monthDropdown-months,
.flatpickr-current-month input.cur-year {
  @apply font-bold;
}
</style>
