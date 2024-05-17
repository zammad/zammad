<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, toRef } from 'vue'

import CommonTicketStateIndicator from '#shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import useValue from '#shared/components/Form/composables/useValue.ts'
import type { SelectContext } from '#shared/components/Form/fields/FieldSelect/types.ts'
import useSelectOptions from '#shared/composables/useSelectOptions.ts'
import useSelectPreselect from '#shared/composables/useSelectPreselect.ts'
import { useFormBlock } from '#shared/form/useFormBlock.ts'
import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import CommonSelect from '#mobile/components/CommonSelect/CommonSelect.vue'
import type { CommonSelectInstance } from '#mobile/components/CommonSelect/types.ts'

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
  setupMissingOrDisabledOptionHandling,
} = useSelectOptions(toRef(props.context, 'options'), contextReactive)

const select = ref<CommonSelectInstance>()

const openSelectDialog = () => {
  if (
    select.value?.isOpen ||
    !props.context.options?.length ||
    props.context.disabled
  )
    return
  select.value?.openDialog()
}

useFormBlock(contextReactive, openSelectDialog)

useSelectPreselect(sortedOptions, contextReactive)
setupMissingOrDisabledOptionHandling()
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
      #default="{ state: expanded }"
      :model-value="currentValue"
      :options="sortedOptions"
      :multiple="context.multiple"
      :owner="context.id"
      no-options-label-translation
      passive
      @select="selectOption"
    >
      <output
        :id="context.id"
        ref="outputElement"
        role="combobox"
        aria-controls="common-select"
        aria-owns="common-select"
        aria-haspopup="dialog"
        :aria-expanded="expanded"
        :name="context.node.name"
        class="formkit-disabled:pointer-events-none flex grow items-center focus:outline-none"
        :aria-labelledby="`label-${context.id}`"
        :aria-disabled="context.disabled"
        :data-multiple="context.multiple"
        tabindex="0"
        v-bind="context.attrs"
        @keyup.shift.down.prevent="openSelectDialog()"
        @keypress.space.prevent="openSelectDialog()"
        @blur="context.handlers.blur"
      >
        <div v-if="hasValue" class="flex grow flex-wrap gap-1" role="list">
          <template v-if="hasValue && hasStatusProperty">
            <CommonTicketStateIndicator
              v-for="selectedValue in valueContainer"
              :key="selectedValue"
              :color-code="
                getSelectedOptionStatus(
                  selectedValue,
                ) as EnumTicketStateColorCode
              "
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
              v-for="(selectedValue, idx) in valueContainer"
              :key="selectedValue"
              class="flex items-center text-base leading-[19px]"
              role="listitem"
            >
              <CommonIcon
                v-if="getSelectedOptionIcon(selectedValue)"
                :name="getSelectedOptionIcon(selectedValue)"
                size="tiny"
                class="ltr:mr-1 rtl:ml-1"
                decorative
              />{{
                getSelectedOptionLabel(selectedValue) ||
                i18n.t('%s (unknown)', selectedValue)
              }}{{ idx === valueContainer.length - 1 ? '' : ',' }}
            </div>
          </template>
        </div>
        <CommonIcon
          v-if="context.clearable && hasValue && !context.disabled"
          :aria-label="i18n.t('Clear Selection')"
          class="text-gray absolute -mt-5 shrink-0 ltr:right-2 rtl:left-2"
          name="close-small"
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
