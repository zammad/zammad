<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import {
  Dialog,
  DialogOverlay,
  TransitionRoot,
  TransitionChild,
} from '@headlessui/vue'
import { i18n } from '@shared/i18n'
import CommonTicketStateIndicator from '@shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import useValue from '@shared/components/Form/composables/useValue'
import useSelectDialog from '@shared/components/Form/composables/useSelectDialog'
import useSelectOptions from '@shared/components/Form/composables/useSelectOptions'
import useSelectAutoselect from '@shared/components/Form/composables/useSelectAutoselect'
import type { FormFieldContext } from '@shared/components/Form/types/field'
import type {
  SelectOption,
  SelectOptionSorting,
  SelectSize,
} from '@shared/components/Form/fields/FieldSelect/types'

interface Props {
  context: FormFieldContext<{
    autoselect?: boolean
    clearable?: boolean
    disabled?: boolean
    multiple?: boolean
    noOptionsLabelTranslation?: boolean
    options: SelectOption[]
    size?: SelectSize
    sorting?: SelectOptionSorting
  }>
}

const props = defineProps<Props>()

const { hasValue, valueContainer, isCurrentValue, clearValue } = useValue(
  toRef(props, 'context'),
)

const { isOpen, setIsOpen } = useSelectDialog()

const {
  dialog,
  hasStatusProperty,
  sortedOptions,
  getSelectedOptionIcon,
  getSelectedOptionLabel,
  getSelectedOptionStatus,
  selectOption,
  advanceDialogFocus,
} = useSelectOptions(toRef(props.context, 'options'), toRef(props, 'context'))

const select = (option: SelectOption) => {
  selectOption(option)
  if (!props.context.multiple) setIsOpen(false)
}

const isSizeSmall = computed(() => props.context.size === 'small')

useSelectAutoselect(sortedOptions, toRef(props, 'context'))
</script>

<template>
  <div
    v-bind:class="{
      [context.classes.input]: true,
      'min-h-[3.5rem] bg-transparent rounded-none': !isSizeSmall,
      'bg-gray-600 rounded-lg w-auto': isSizeSmall,
    }"
    class="flex h-auto focus-within:bg-blue-highlight focus-within:pt-0 formkit-populated:pt-0"
    data-test-id="field-select"
  >
    <output
      v-bind:id="context.id"
      v-bind:name="context.node.name"
      v-bind:class="{
        'px-3 grow': !isSizeSmall,
        'px-2 py-1': isSizeSmall,
      }"
      class="flex cursor-pointer items-center focus:outline-none formkit-disabled:pointer-events-none"
      v-bind:aria-disabled="context.disabled"
      v-bind:aria-label="i18n.t('Select...')"
      v-bind:tabindex="context.disabled ? '-1' : '0'"
      v-bind="context.attrs"
      role="list"
      v-on:click="setIsOpen(true)"
      v-on:keypress.space="setIsOpen(true)"
      v-on:blur="context.handlers.blur"
    >
      <div
        v-bind:class="{
          'translate-y-2 grow': !isSizeSmall,
        }"
        class="flex flex-wrap gap-1"
      >
        <template v-if="hasValue && hasStatusProperty">
          <CommonTicketStateIndicator
            v-for="selectedValue in valueContainer"
            v-bind:key="selectedValue"
            v-bind:status="getSelectedOptionStatus(selectedValue)"
            v-bind:label="getSelectedOptionLabel(selectedValue)"
            v-bind:data-test-status="getSelectedOptionStatus(selectedValue)"
            role="listitem"
            pill
          />
        </template>
        <template v-else-if="hasValue">
          <div
            v-for="selectedValue in valueContainer"
            v-bind:key="selectedValue"
            v-bind:class="{
              'text-base leading-[19px]': !isSizeSmall,
              'mr-1 text-sm leading-[17px]': isSizeSmall,
            }"
            class="flex items-center after:content-[','] last:after:content-none"
            role="listitem"
          >
            <CommonIcon
              v-if="getSelectedOptionIcon(selectedValue)"
              v-bind:name="getSelectedOptionIcon(selectedValue)"
              v-bind:fixed-size="{ width: 12, height: 12 }"
              class="mr-1"
            />
            {{ getSelectedOptionLabel(selectedValue) || selectedValue }}
          </div>
        </template>
        <template v-else-if="isSizeSmall">
          <div class="mr-1 text-sm leading-[17px]">
            {{ i18n.t(context.label) }}
          </div>
        </template>
      </div>
      <CommonIcon
        v-if="context.clearable && hasValue && !context.disabled"
        v-bind:aria-label="i18n.t('Clear Selection')"
        v-bind:fixed-size="{ width: 16, height: 16 }"
        class="mr-2 shrink-0"
        name="close-small"
        role="button"
        tabindex="0"
        v-on:click.stop="clearValue"
        v-on:keypress.space.prevent.stop="clearValue"
      />
      <CommonIcon
        v-bind:fixed-size="{ width: 16, height: 16 }"
        class="shrink-0"
        name="caret-down"
        decorative
      />
    </output>
    <TransitionRoot v-bind:show="isOpen" as="template" appear>
      <Dialog
        class="fixed inset-0 z-10 flex overflow-y-auto py-6"
        role="dialog"
        v-on:close="setIsOpen(false)"
      >
        <TransitionChild
          enter="duration-300 ease-out"
          enter-from="opacity-0"
          enter-to="opacity-100"
          leave="duration-200 ease-in"
          leave-from="opacity-100"
          leave-to="opacity-0"
        >
          <DialogOverlay
            class="fixed inset-0 bg-gray-500 opacity-60"
            data-test-id="dialog-overlay"
          />
        </TransitionChild>
        <TransitionChild
          class="relative m-auto"
          enter="duration-300 ease-out"
          enter-from="opacity-0 scale-95"
          enter-to="opacity-100 scale-100"
          leave="duration-200 ease-in"
          leave-from="opacity-100 scale-100"
          leave-to="opacity-0 scale-95"
        >
          <div
            ref="dialog"
            class="flex min-w-[294px] flex-col items-start divide-y divide-solid divide-white/10 rounded-xl bg-gray-400/80 backdrop-blur-[15px]"
            role="listbox"
          >
            <div
              v-for="option in sortedOptions"
              v-bind:key="option.value"
              v-bind:class="{
                'pointer-events-none': option.disabled,
              }"
              v-bind:tabindex="option.disabled ? '-1' : '0'"
              v-bind:aria-selected="isCurrentValue(option.value)"
              class="flex h-[58px] cursor-pointer items-center self-stretch py-5 px-4 text-base leading-[19px] text-white first:rounded-t-xl last:rounded-b-xl focus:bg-blue-highlight focus:outline-none"
              role="option"
              v-on:click="select(option)"
              v-on:keypress.space="select(option)"
              v-on:keydown="advanceDialogFocus"
            >
              <CommonIcon
                v-if="context.multiple"
                v-bind:class="{
                  '!text-white': isCurrentValue(option.value),
                  'opacity-30': option.disabled,
                }"
                v-bind:fixed-size="{ width: 24, height: 24 }"
                v-bind:name="
                  isCurrentValue(option.value) ? 'checked-yes' : 'checked-no'
                "
                class="mr-3 text-white/50"
              />
              <CommonTicketStateIndicator
                v-if="option.status"
                v-bind:status="option.status"
                v-bind:label="option.label"
                v-bind:class="{
                  'opacity-30': option.disabled,
                }"
                class="mr-[11px]"
              />
              <CommonIcon
                v-else-if="option.icon"
                v-bind:name="option.icon"
                v-bind:fixed-size="{ width: 16, height: 16 }"
                v-bind:class="{
                  '!text-white': isCurrentValue(option.value),
                  'opacity-30': option.disabled,
                }"
                class="mr-[11px] text-white/80"
              />
              <span
                v-bind:class="{
                  'font-semibold !text-white': isCurrentValue(option.value),
                  'opacity-30': option.disabled,
                }"
                class="grow text-white/80"
              >
                {{ option.label || option.value }}
              </span>
              <CommonIcon
                v-if="!context.multiple && isCurrentValue(option.value)"
                v-bind:class="{
                  'opacity-30': option.disabled,
                }"
                v-bind:fixed-size="{ width: 16, height: 16 }"
                name="check"
              />
            </div>
          </div>
        </TransitionChild>
      </Dialog>
    </TransitionRoot>
  </div>
</template>

<style lang="scss">
.field-select {
  &.floating-input:focus-within:not([data-populated]) label {
    @apply translate-y-0 translate-x-0 scale-100 opacity-100;
  }

  .formkit-label {
    @apply py-4;
  }

  .formkit-inner {
    @apply flex;
  }
}
</style>
