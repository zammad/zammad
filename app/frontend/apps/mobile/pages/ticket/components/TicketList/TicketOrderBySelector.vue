<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSelect from '@mobile/components/CommonSelect/CommonSelect.vue'
import type { CommonSelectInstance } from '@mobile/components/CommonSelect/types'
import type { Sizes } from '@shared/components/CommonIcon/types'
import type { SelectOption } from '@shared/components/Form/fields/FieldSelect'
import { EnumOrderDirection } from '@shared/graphql/types'
import { i18n } from '@shared/i18n'
import stopEvent from '@shared/utils/events'
import { useVModel } from '@vueuse/core'
import { computed, ref } from 'vue'

interface Props {
  orderBy?: string
  options: SelectOption[]
  direction?: EnumOrderDirection
  label: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  (e: 'update:orderBy', value: string): void
  (e: 'update:direction', value: EnumOrderDirection): void
}>()

const localOrderBy = useVModel(props, 'orderBy', emit)
const localDirection = useVModel(props, 'direction', emit)

const accessibilityLabel = computed(() => {
  return i18n.t(
    'Tickets are ordered by "%s" column (%s).',
    i18n.t(props.label),
    props.direction === EnumOrderDirection.Ascending
      ? i18n.t('ascending')
      : i18n.t('descending'),
  )
})

const directionOptions = computed(() => [
  {
    value: EnumOrderDirection.Descending,
    label: __('descending'),
    icon: 'mobile-arrow-down',
    iconProps: {
      class: {
        'text-blue': props.direction === EnumOrderDirection.Descending,
      },
      size: 'tiny' as Sizes,
    },
  },
  {
    value: EnumOrderDirection.Ascending,
    label: __('ascending'),
    icon: 'mobile-arrow-up',
    iconProps: {
      class: [
        {
          'text-blue': props.direction === EnumOrderDirection.Ascending,
        },
      ],
      size: 'tiny' as Sizes,
    },
  },
])

const directionElement = ref<HTMLDivElement>()
const selectButton = ref<HTMLButtonElement>()

const selector = ref<CommonSelectInstance>()

const advanceFocus = (event: KeyboardEvent, idx: number) => {
  const { key } = event
  if (!['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(event.key))
    return

  stopEvent(event)

  if (key === 'ArrowUp' || key === 'ArrowDown') {
    const elements = selector.value?.getFocusableOptions() || []
    const index = key === 'ArrowDown' ? 0 : elements.length - 3 // -3 because of the direction buttons
    elements[index]?.focus()
    elements[index]?.scrollIntoView({ block: 'nearest' })
    return
  }

  // go either left or right
  const nextIndex = idx === 1 ? 0 : 1
  const elements = directionElement.value?.querySelectorAll('button') || []

  elements[nextIndex]?.focus()
}
</script>

<template>
  <CommonSelect
    ref="selector"
    v-model="localOrderBy"
    :options="options"
    no-close
  >
    <template #default="{ open }">
      <button
        ref="selectButton"
        role="button"
        :aria-label="accessibilityLabel"
        class="flex cursor-pointer items-center gap-1 overflow-hidden whitespace-nowrap text-blue"
        data-test-id="column"
        @click="open"
        @keydown.space.prevent="open"
      >
        <div>
          <CommonIcon
            decorative
            :name="
              direction === EnumOrderDirection.Ascending
                ? 'mobile-arrow-up'
                : 'mobile-arrow-down'
            "
            size="tiny"
          />
        </div>
        <span class="overflow-hidden text-ellipsis whitespace-nowrap">
          {{ $t(label) }}
        </span>
      </button>
    </template>

    <template #footer>
      <div ref="directionElement" class="flex gap-2 p-3 text-white">
        <button
          v-for="(option, idx) of directionOptions"
          :key="option.value"
          class="flex flex-1 cursor-pointer items-center justify-center rounded-md p-2"
          :class="{
            'bg-gray-200 font-bold': option.value === direction,
          }"
          :aria-pressed="option.value === direction"
          type="button"
          tabindex="0"
          @click="localDirection = option.value"
          @keydown="advanceFocus($event, idx)"
          @keydown.space.prevent="localDirection = option.value"
        >
          <CommonIcon
            v-if="option.icon"
            :name="option.icon"
            decorative
            class="ltr:mr-1 rtl:ml-1"
            v-bind="option.iconProps"
          />
          {{ option.label }}
        </button>
      </div>
    </template>
  </CommonSelect>
</template>
