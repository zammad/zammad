<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, toRef } from 'vue'
import { i18n } from '@shared/i18n'
import CommonTicketStateIndicator from '@shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import CommonSelect from '@mobile/components/CommonSelect/CommonSelect.vue'
import type { CommonSelectInstance } from '@mobile/components/CommonSelect/types'
import { useFormBlock } from '@mobile/form/useFormBlock'
import useValue from '../../composables/useValue'
import useSelectOptions from '../../composables/useSelectOptions'
import useSelectPreselect from '../../composables/useSelectPreselect'
import type { SelectContext } from './types'
import FieldSelectInputSelected from './FieldSelectInputSelected.vue'

interface Props {
  context: SelectContext
}

const props = defineProps<Props>()

const contextReactive = toRef(props, 'context')

const { hasValue, valueContainer, currentValue, clearValue } =
  useValue(contextReactive)

const {
  hasStatusProperty,
  sortedOptions,
  selectOption,
  getSelectedOptionIcon,
  getSelectedOptionLabel,
  getSelectedOptionStatus,
} = useSelectOptions(toRef(props.context, 'options'), contextReactive)

const isSizeSmall = computed(() => props.context.size === 'small')

const select = ref<CommonSelectInstance>()

const openSelectDialog = () => {
  if (select.value?.isOpen) return
  select.value?.openDialog()
}

useFormBlock(props.context, openSelectDialog)

useSelectPreselect(sortedOptions, toRef(props, 'context'))
</script>

<template>
  <div
    :class="[
      {
        [context.classes.input]: !isSizeSmall,
        'flex h-auto formkit-populated:pt-0': !isSizeSmall,
        'w-auto rounded-lg bg-gray-600': isSizeSmall,
      },
    ]"
    data-test-id="field-select"
  >
    <CommonSelect
      ref="select"
      :model-value="currentValue"
      :options="sortedOptions"
      :multiple="context.multiple"
      no-options-label-translation
      passive
      @select="selectOption"
    >
      <output
        :id="context.id"
        :name="context.node.name"
        :class="{
          'grow pr-3': !isSizeSmall,
          'ltr:pl-2 ltr:pr-1 rtl:pr-2 rtl:pl-1': isSizeSmall,
        }"
        class="flex cursor-pointer items-center focus:outline-none formkit-disabled:pointer-events-none"
        :aria-disabled="context.disabled"
        :aria-label="i18n.t('Select…')"
        :tabindex="context.disabled ? '-1' : '0'"
        v-bind="{
          ...context.attrs,
          onBlur: undefined,
        }"
        @keypress.space="openSelectDialog()"
        @blur="context.handlers.blur"
      >
        <div
          v-if="hasValue || isSizeSmall"
          :class="{
            grow: !isSizeSmall,
          }"
          class="flex flex-wrap gap-1"
          role="list"
        >
          <template v-if="hasValue && hasStatusProperty">
            <CommonTicketStateIndicator
              v-for="selectedValue in valueContainer"
              :key="selectedValue"
              :status="getSelectedOptionStatus(selectedValue)"
              :label="getSelectedOptionLabel(selectedValue)"
              :data-test-status="getSelectedOptionStatus(selectedValue)"
              role="listitem"
              pill
            />
          </template>
          <template v-else-if="hasValue">
            <div
              v-for="selectedValue in valueContainer"
              :key="selectedValue"
              :class="{
                'text-base leading-[19px]': !isSizeSmall,
                'mr-1 py-1': isSizeSmall,
              }"
              class="flex items-center after:content-[','] last:after:content-none"
              role="listitem"
            >
              <CommonIcon
                v-if="getSelectedOptionIcon(selectedValue)"
                :name="getSelectedOptionIcon(selectedValue)"
                :fixed-size="{ width: 12, height: 12 }"
                class="mr-1"
              />
              <FieldSelectInputSelected
                :slotted="(context.slots as any)?.output"
                :label="getSelectedOptionLabel(selectedValue) || selectedValue"
                :small="isSizeSmall"
              />
            </div>
          </template>
          <template v-else-if="isSizeSmall">
            <div
              class="mr-1 overflow-hidden text-ellipsis whitespace-nowrap py-1 text-sm leading-[17px]"
              role="listitem"
            >
              {{ i18n.t(context.label) }}
            </div>
          </template>
        </div>
        <CommonIcon
          v-if="context.clearable && hasValue && !context.disabled"
          :aria-label="i18n.t('Clear Selection')"
          :fixed-size="{ width: 16, height: 16 }"
          class="mr-2 shrink-0"
          name="close-small"
          role="button"
          tabindex="0"
          @click.stop="clearValue"
          @keypress.space.prevent.stop="clearValue"
        />
        <CommonIcon
          v-if="isSizeSmall"
          :fixed-size="{ width: 16, height: 16 }"
          class="shrink-0"
          name="caret-down"
          decorative
        />
      </output>
    </CommonSelect>
  </div>
</template>
