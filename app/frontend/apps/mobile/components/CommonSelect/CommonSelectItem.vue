<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonTicketStateIndicator from '#shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import { computed } from 'vue'
import { i18n } from '#shared/i18n.ts'
import type { SelectOption } from '#shared/components/CommonSelect/types.ts'

const props = defineProps<{
  option: SelectOption
  selected: boolean
  multiple?: boolean
  noLabelTranslate?: boolean
}>()

const emit = defineEmits<{
  (e: 'select', option: SelectOption): void
}>()

const select = (option: SelectOption) => {
  if (props.option.disabled) {
    return
  }
  emit('select', option)
}

const label = computed(() => {
  const { option } = props
  if (props.noLabelTranslate) {
    return option.label
  }

  return i18n.t(option.label, ...(option.labelPlaceholder || []))
})
</script>

<template>
  <div
    :class="{
      'pointer-events-none': option.disabled,
    }"
    :tabindex="option.disabled ? '-1' : '0'"
    :aria-selected="selected"
    class="flex h-[58px] cursor-pointer items-center self-stretch px-4 py-5 text-base leading-[19px] text-white first:rounded-t-xl last:rounded-b-xl focus:bg-blue-highlight focus:outline-none"
    role="option"
    :data-value="option.value"
    @click="select(option)"
    @keypress.space.prevent="select(option)"
  >
    <CommonIcon
      v-if="multiple"
      :class="{
        '!text-white': selected,
        'opacity-30': option.disabled,
      }"
      size="base"
      decorative
      :name="selected ? 'mobile-check-box-yes' : 'mobile-check-box-no'"
      class="text-white/50 ltr:mr-3 rtl:ml-3"
    />
    <CommonTicketStateIndicator
      v-if="option.status"
      :color-code="option.status"
      :label="option.label || String(option.value)"
      :class="{
        'opacity-30': option.disabled,
      }"
      class="ltr:mr-[11px] rtl:ml-[11px]"
    />
    <CommonIcon
      v-else-if="option.icon"
      :name="option.icon"
      size="small"
      :class="{
        '!text-white': selected,
        'opacity-30': option.disabled,
      }"
      decorative
      class="text-white/80 ltr:mr-[11px] rtl:ml-[11px]"
    />
    <span
      :class="{
        'font-semibold !text-white': selected,
        'opacity-30': option.disabled,
      }"
      class="grow text-white/80"
    >
      {{ label || option.value }}
    </span>
    <CommonIcon
      v-if="!multiple"
      class="ltr:ml-2 rtl:mr-2"
      :class="{
        invisible: !selected,
        'opacity-30': option.disabled,
      }"
      decorative
      size="tiny"
      name="mobile-check"
    />
  </div>
</template>
