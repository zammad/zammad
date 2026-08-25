<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, ref, toRef, watch } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { useDelegateFocus } from '#shared/composables/useDelegateFocus.ts'

import type { RadioListOption, RadioListOptionValue } from './types.ts'

const props = defineProps<{
  context: FormFieldContext<{
    options: RadioListOption[]
  }>
}>()

const context = toRef(props, 'context')

const { hasValue, localValue } = useValue(context)

const { delegateFocus } = useDelegateFocus(
  context.value.id,
  `radio_list_radio_${context.value.id}_${context.value?.options && context.value?.options[0]?.value}`,
)

// Option values arrive as numbers and as strings alike, and an option value of `null` has to
//   answer for a field that holds no value at all - so they are compared loosely, the way the
//   value comparison this state replaces did.
const isSameOptionValue = (
  value?: RadioListOptionValue | null,
  otherValue?: RadioListOptionValue | null,
  // oxlint-disable-next-line eqeqeq
) => value == otherValue

// Which option is checked, kept as state of its own rather than derived from the value: an option
//   that owns a date field commits *that date* as the value of the field, so until a date is
//   picked it leaves the field empty - which no comparison can tell apart from an option whose
//   value is empty by design (the "now" of a scheduled publication).
const selectedOptionValue = ref<RadioListOptionValue | null>()

const isSelected = (option: RadioListOption) =>
  isSameOptionValue(option.value, selectedOptionValue.value)

// The date option in play, which is the one that is picked - not simply the first one that owns a
//   date: several options may, and each of them commits its own timestamp as the value of the
//   field while it is selected.
const selectedDateOption = computed(() =>
  context.value.options?.find((option) => option.dateField && isSelected(option)),
)

// Where a value that none of the options owns has to go, since a bare timestamp names no option it
//   belongs to: the first option that takes one. Only reachable with several of them, and only
//   until one is picked - what a field with two date options cannot do is *restore* which of them
//   a stored date answered.
const firstDateOption = computed(() => context.value.options?.find((option) => option.dateField))

// Identifies the picker of the selected option, so picking the option can hand it the focus. One
//   id for all of them: only the picked option renders its picker.
const dateFieldId = computed(() => `radio_list_date_${context.value.id}`)

const isDateOptionSelected = computed(() => Boolean(selectedDateOption.value))

// Whether the field itself is what left the value empty - picking the date option, or clearing
//   its picker. Only then does the option stay selected, waiting for the date it asks for. An
//   empty value the field is *handed* means the opposite (another session switching a scheduled
//   draft back to "now", restored through the taskbar), and the value alone cannot tell the two
//   apart. Read once, by the round of the watcher below that the emptying triggers.
let emptiedHere = false

// Follows a value the field did not set itself - the form updater restoring a stored draft, above
//   all. A value that none of the plain options owns is the date of the date option.
watch(
  localValue,
  (value) => {
    const wasEmptiedHere = emptiedHere
    emptiedHere = false

    // An empty value of this field's own making does not unselect the date option: it is picked,
    //   only not filled in yet, which is what the validation of the field reports.
    if (isDateOptionSelected.value && !hasValue.value && wasEmptiedHere) return

    const option = context.value.options?.find(
      (option) => !option.dateField && isSameOptionValue(option.value, value),
    )

    if (option) {
      selectedOptionValue.value = option.value
      return
    }

    // The date option in play keeps the value it just committed; only a value that arrives while
    //   no date option is picked has to be given one.
    selectedOptionValue.value = hasValue.value
      ? (selectedDateOption.value ?? firstDateOption.value)?.value
      : undefined
  },
  { immediate: true },
)

// What the validation of the field goes by: an option that owns a date field is not answered by
//   picking it (see addOptionDateValidation).
watch(
  isDateOptionSelected,
  (selected) => {
    context.value.node.props.dateOptionSelected = selected
  },
  { immediate: true },
)

// While its option is picked, the value of the field *is* the date, so the picker edits it
//   directly. Nothing of it outlives the option: picking another one clears the field.
const dateValue = computed({
  get: () => (isDateOptionSelected.value ? ((localValue.value ?? null) as string | null) : null),
  set: (value: string | null) => {
    // Clearing the picker leaves its own option selected, so the field goes on reporting the
    //   missing date instead of moving the selection elsewhere.
    emptiedHere = !value

    localValue.value = value ?? null
  },
})

const selectOption = async (option: RadioListOption, event?: Event) => {
  const wasSelected = isSelected(option)

  selectedOptionValue.value = option.value

  // An option that owns a date field is answered by the date below it, so picking the option
  //   itself commits nothing - and picking it again must not throw away a date already there.
  if (!option.dateField) {
    localValue.value = option.value
  } else if (!wasSelected) {
    emptiedHere = true

    localValue.value = null
  }

  // An option that owns a date field asks for that date next, so it takes the focus over the
  //   option itself - one render later, which is the first the picker exists in.
  if (option.dateField) {
    await nextTick()

    document.getElementById(dateFieldId.value)?.focus()

    return
  }

  const targetElement = (event?.target as Element)
    ?.closest('.group')
    ?.querySelector('.icon') as HTMLElement

  targetElement?.focus()
}
</script>

<template>
  <output
    :id="context.id"
    class="flex flex-col items-start rounded-lg bg-blue-200 focus:outline focus:outline-offset-1 focus:outline-blue-800 hover:focus:outline-blue-800 dark:bg-gray-700"
    role="radiogroup"
    :class="context.classes.input"
    :name="context.node.name"
    :aria-disabled="context.disabled"
    :aria-describedby="context.describedBy"
    tabindex="0"
    v-bind="context.attrs"
    @focus="delegateFocus"
  >
    <div
      v-for="option in context.options"
      :key="`option-${option.value}`"
      class="flex w-full flex-col items-start"
    >
      <!-- eslint-disable vuejs-accessibility/interactive-supports-focus   -->
      <div
        class="group inline-flex cursor-pointer gap-2.5 px-3 py-2.5"
        role="radio"
        :aria-disabled="context.disabled"
        :aria-checked="isSelected(option)"
        :aria-label="option.label"
        @click.stop="selectOption(option, $event)"
        @keydown.enter.stop="selectOption(option, $event)"
      >
        <CommonIcon
          :id="`radio_list_radio_${context.id}_${option.value}`"
          size="small"
          tabindex="0"
          class="shrink-0 self-start rounded-full group-hover:outline group-hover:-outline-offset-1 group-hover:outline-blue-600 focus:outline focus:-outline-offset-1 focus:outline-blue-800 group-hover:focus:outline-blue-800 dark:group-hover:outline-blue-900 dark:group-hover:focus:outline-blue-800 formkit-disabled:pointer-events-none"
          :class="{
            'formkit-invalid:outline-red-500 dark:hover:formkit-invalid:outline-red-500 formkit-errors:outline formkit-errors:-outline-offset-1 formkit-errors:outline-red-500 dark:hover:formkit-errors:outline-red-500':
              isSelected(option),
          }"
          :name="isSelected(option) ? 'radio-yes' : 'radio-no'"
          @keydown.space.prevent="selectOption(option)"
        />

        <div class="flex flex-col" tabindex="-1">
          <CommonLabel class="text-black! dark:text-white!">
            {{ $t(option.label) }}
          </CommonLabel>

          <CommonLabel v-if="option.description" class="text-stone-200! dark:text-neutral-500!">
            {{ $t(option.description) }}
          </CommonLabel>
        </div>
      </div>

      <!-- Inside the group and below the option it belongs to, indented by the width of the radio
             button in front of the option label, so it reads as part of that one option. Outside
             the `radio` element on purpose: an interactive control inside it would swallow the
             clicks that pick the option, and belongs to no radio button in the first place. -->
      <div v-if="option.dateField && isSelected(option)" class="w-full ps-10.5 pe-3 pb-3">
        <FormKit
          :id="dateFieldId"
          v-model="dateValue"
          type="datetime"
          :ignore="true"
          :label="option.dateField.label"
          :label-sr-only="true"
          :alternative-background="true"
          :disabled="context.disabled"
          :future-only="option.dateField.futureOnly"
          :past-only="option.dateField.pastOnly"
          :min-date="option.dateField.minDate"
          :max-date="option.dateField.maxDate"
          @blur="context.handlers.blur"
        />
      </div>
    </div>
  </output>
</template>
