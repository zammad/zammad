<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { markRaw, ref, toRef } from 'vue'
import { i18n } from '@shared/i18n'
import { useDialog } from '@shared/composables/useDialog'
import useLocaleStore from '@shared/stores/locale'
import useValue from '../../composables/useValue'
import useSelectOptions from '../../composables/useSelectOptions'
import useSelectAutoselect from '../../composables/useSelectAutoselect'
import type { FormFieldContext } from '../../types/field'
import type { AutoCompleteOption, AutoCompleteProps } from './types'

interface Props {
  context: FormFieldContext<
    AutoCompleteProps & {
      gqlQuery: string
    }
  >
}

const props = defineProps<Props>()

const { hasValue, valueContainer, clearValue } = useValue(
  toRef(props, 'context'),
)

const localOptions = ref(props.context.options || [])

const nameDialog = `field-auto-complete-${props.context.id}`

const dialog = useDialog({
  name: nameDialog,
  prefetch: true,
  component: () => import('./FieldAutoCompleteInputDialog.vue'),
})

const openModal = () => {
  return dialog.open({
    context: toRef(props, 'context'),
    name: nameDialog,
    options: localOptions,
    optionIconComponent: props.context.optionIconComponent
      ? markRaw(props.context.optionIconComponent)
      : null,
    onUpdateOptions: (options: AutoCompleteOption[]) => {
      localOptions.value = options
    },
  })
}

const { sortedOptions, getSelectedOptionIcon, getSelectedOptionLabel } =
  useSelectOptions(localOptions, toRef(props, 'context'))

const toggleDialog = async (isVisible: boolean) => {
  if (isVisible) {
    await openModal()
    return
  }

  await dialog.close()
}

useSelectAutoselect(sortedOptions, toRef(props, 'context'))

const locale = useLocaleStore()
</script>

<template>
  <div
    :class="{
      [context.classes.input]: true,
    }"
    class="flex h-auto min-h-[3.5rem] rounded-none bg-transparent focus-within:bg-blue-highlight focus-within:pt-0 formkit-populated:pt-0"
    data-test-id="field-autocomplete"
  >
    <output
      :id="context.id"
      :name="context.node.name"
      class="flex grow cursor-pointer items-center focus:outline-none formkit-disabled:pointer-events-none ltr:pr-3 rtl:pl-3"
      :aria-disabled="context.disabled"
      :aria-label="i18n.t('Select…')"
      :tabindex="context.disabled ? '-1' : '0'"
      v-bind="context.attrs"
      role="list"
      @click="toggleDialog(true)"
      @keypress.space="toggleDialog(true)"
      @blur="context.handlers.blur"
    >
      <div class="flex grow translate-y-2 flex-wrap gap-1">
        <template v-if="hasValue">
          <div
            v-for="selectedValue in valueContainer"
            :key="selectedValue"
            class="flex items-center text-base leading-[19px] after:content-[','] last:after:content-none"
            role="listitem"
          >
            <CommonIcon
              v-if="getSelectedOptionIcon(selectedValue)"
              :name="getSelectedOptionIcon(selectedValue)"
              :fixed-size="{ width: 12, height: 12 }"
              class="mr-1"
            />
            {{ getSelectedOptionLabel(selectedValue) || selectedValue }}
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
        :fixed-size="{ width: 24, height: 24 }"
        class="shrink-0"
        :name="`chevron-${locale.localeData?.dir === 'rtl' ? 'left' : 'right'}`"
        decorative
      />
    </output>
  </div>
</template>

<style lang="scss">
.field-autocomplete {
  &.floating-input:focus-within:not([data-populated]) {
    label {
      @apply translate-y-0 translate-x-0 scale-100 opacity-100;
    }
  }

  .formkit-label {
    @apply py-4;
  }
}
</style>
