<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, toRef } from 'vue'
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
  setupMissingOptionHandling,
} = useSelectOptions(toRef(props.context, 'options'), contextReactive)

const select = ref<CommonSelectInstance>()

const openSelectDialog = () => {
  if (select.value?.isOpen || !props.context.options?.length) return
  select.value?.openDialog()
}

useFormBlock(contextReactive, openSelectDialog)

useSelectPreselect(sortedOptions, contextReactive)
setupMissingOptionHandling()
</script>

<template>
  <div
    :class="[
      context.classes.input,
      'flex h-auto',
      {
        'ltr:pr-9 rtl:pl-9': context.clearable && hasValue && !context.disabled,
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
        ref="outputElement"
        :name="context.node.name"
        class="flex grow items-center focus:outline-none formkit-disabled:pointer-events-none"
        :aria-disabled="context.disabled"
        :aria-label="i18n.t('Select…')"
        :data-multiple="context.multiple"
        :tabindex="context.disabled ? '-1' : '0'"
        v-bind="{
          ...context.attrs,
          onBlur: undefined,
        }"
        @keypress.space.prevent="openSelectDialog()"
        @blur="context.handlers.blur"
      >
        <div v-if="hasValue" class="flex grow flex-wrap gap-1" role="list">
          <template v-if="hasValue && hasStatusProperty">
            <CommonTicketStateIndicator
              v-for="selectedValue in valueContainer"
              :key="selectedValue"
              :status="getSelectedOptionStatus(selectedValue)"
              :label="
                getSelectedOptionLabel(selectedValue) ||
                i18n.t('%s (unknown)', selectedValue)
              "
              :data-test-status="getSelectedOptionStatus(selectedValue)"
              role="listitem"
              pill
            />
          </template>
          <template v-else-if="hasValue">
            <div
              v-for="selectedValue in valueContainer"
              :key="selectedValue"
              class="flex items-center text-base leading-[19px] after:content-[','] last:after:content-none"
              role="listitem"
            >
              <CommonIcon
                v-if="getSelectedOptionIcon(selectedValue)"
                :name="getSelectedOptionIcon(selectedValue)"
                size="tiny"
                class="mr-1"
              />
              <FieldSelectInputSelected
                :slotted="(context.slots as any)?.output"
                :label="
                  getSelectedOptionLabel(selectedValue) ||
                  i18n.t('%s (unknown)', selectedValue)
                "
              />
            </div>
          </template>
        </div>
        <CommonIcon
          v-if="context.clearable && hasValue && !context.disabled"
          :aria-label="i18n.t('Clear Selection')"
          class="absolute -mt-5 shrink-0 text-gray ltr:right-2 rtl:left-2"
          name="mobile-close-small"
          size="base"
          role="button"
          tabindex="0"
          @click.stop="clearValue()"
          @keypress.space.prevent.stop="clearValue()"
        />
      </output>
    </CommonSelect>
  </div>
</template>
