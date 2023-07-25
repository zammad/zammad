<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTraverseOptions } from '#shared/composables/useTraverseOptions.ts'
import { computed, ref, toRef } from 'vue'
import CommonTooltip from '#shared/components/CommonTooltip/CommonTooltip.vue'
import type { TooltipItemDescriptor } from '#shared/components/CommonTooltip/types.ts'
import { i18n } from '#shared/i18n.ts'
import { translateArticleSecurity } from '#shared/entities/ticket-article/composables/translateArticleSecurity.ts'
import useValue from '../../composables/useValue.ts'
import type {
  SecurityOption,
  SecurityValue,
  SecurityMessages,
  SecurityAllowed,
} from './types.ts'
import { EnumSecurityStateType } from './types.ts'
import type { FormFieldContext } from '../../types/field.ts'

interface FieldSecurityProps {
  context: FormFieldContext<{
    disabled?: boolean
    securityAllowed?: SecurityAllowed
    securityMessages?: SecurityMessages
  }>
}

const props = defineProps<FieldSecurityProps>()

const { localValue } = useValue<SecurityValue>(toRef(props, 'context'))

const securityMethods = computed(() => {
  return Object.keys(props.context.securityAllowed || {}).sort((a) => {
    if (a === EnumSecurityStateType.Pgp) return -1
    if (a === EnumSecurityStateType.Smime) return 1
    return 0
  }) as EnumSecurityStateType[]
})

const previewMethod = computed(
  () =>
    localValue.value?.method ??
    // smime should have priority
    (securityMethods.value.find(
      (value) => value === EnumSecurityStateType.Smime,
    ) ||
      securityMethods.value[0]),
)

const filterOptions = (
  method: EnumSecurityStateType,
  options: SecurityOption[],
) => {
  return options
    .filter(
      (option) => props.context.securityAllowed?.[method]?.includes(option),
    )
    .sort()
}

const isCurrentValue = (option: SecurityOption) =>
  localValue.value?.options.includes(option) ?? false

const options = computed(() => {
  return [
    {
      option: 'encryption',
      label: 'Encrypt',
      icon: isCurrentValue('encryption') ? 'mobile-lock' : 'mobile-unlock',
    },
    {
      option: 'sign',
      label: 'Sign',
      icon: isCurrentValue('sign') ? 'mobile-signed' : 'mobile-not-signed',
    },
  ] as const
})

const isDisabled = (option: SecurityOption) =>
  props.context.disabled ||
  !props.context.securityAllowed?.[previewMethod.value]?.includes(option)

const toggleOption = (name: SecurityOption) => {
  if (isDisabled(name)) return
  let currentOptions = localValue.value?.options || []

  if (currentOptions.includes(name))
    currentOptions = currentOptions.filter((option) => option !== name)
  else currentOptions = [...currentOptions, name]

  localValue.value = {
    method: previewMethod.value,
    options: currentOptions.sort(),
  }
}

const optionsContainer = ref<HTMLElement>()

useTraverseOptions(optionsContainer, { direction: 'horizontal' })

const tooltipMessages = computed(() => {
  const messages: TooltipItemDescriptor[] = []
  const method = previewMethod.value
  const { encryption, sign } = props.context.securityMessages?.[method] || {}

  if (encryption) {
    const message = i18n.t(
      encryption.message,
      ...(encryption.messagePlaceholder || []),
    )
    messages.push({
      type: 'text',
      label: `${i18n.t('Encryption:')} ${message}`,
    })
  }

  if (sign) {
    const message = i18n.t(sign.message, ...(sign.messagePlaceholder || []))
    messages.push({
      type: 'text',
      label: `${i18n.t('Sign:')} ${message}`,
    })
  }

  return messages
})

const changeSecurityState = (method: EnumSecurityStateType) => {
  // remove unsupported options
  const newOptions = filterOptions(method, localValue.value?.options || [])
  localValue.value = {
    method,
    options: newOptions,
  }
}
</script>

<template>
  <div
    :id="`${context.node.name}-${context.formId}`"
    :class="context.classes.input"
    class="flex h-auto flex-col gap-2"
  >
    <div
      v-if="securityMethods.length > 1"
      ref="typesContainer"
      role="listbox"
      class="flex flex-1 justify-between gap-2"
      :aria-label="$t('%s (method)', context.label)"
      aria-orientation="horizontal"
    >
      <button
        v-for="securityType of securityMethods"
        :key="securityType"
        type="button"
        tabindex="1"
        role="option"
        class="flex flex-1 select-none items-center justify-center rounded-md px-2 py-1"
        :aria-selected="previewMethod === securityType"
        :class="{
          'bg-white font-semibold text-black': previewMethod === securityType,
          'bg-gray-300': previewMethod !== securityType,
        }"
        @click="changeSecurityState(securityType)"
        @keydown.space.prevent="changeSecurityState(securityType)"
      >
        {{ translateArticleSecurity(securityType) }}
      </button>
    </div>

    <div class="flex justify-between gap-5">
      <CommonTooltip
        v-if="tooltipMessages.length"
        :name="`security-${context.node.name}`"
        :messages="tooltipMessages"
        :heading="__('Security Information')"
      >
        <!-- TODO: use another icon when we figure out desktop icons -->
        <CommonIcon name="mobile-info" size="small" />
      </CommonTooltip>
      <div
        ref="optionsContainer"
        class="flex h-full items-center gap-2"
        role="listbox"
        :aria-label="$t('%s (option)', context.label)"
        aria-multiselectable="true"
        aria-orientation="horizontal"
      >
        <button
          v-for="{ option, label, icon } of options"
          :key="option"
          type="button"
          role="option"
          class="flex select-none items-center gap-1 rounded-md px-2 py-1 text-base"
          :class="{
            'bg-gray-600/50 text-white/30': isDisabled(option),
            'cursor-pointer': !isDisabled(option),
            'bg-gray-300 text-white': !isCurrentValue(option),
            'bg-white font-semibold text-black': isCurrentValue(option),
          }"
          :tabindex="isDisabled(option) ? -1 : 0"
          :disabled="isDisabled(option)"
          :aria-selected="isCurrentValue(option)"
          :aria-disabled="isDisabled(option)"
          @click="toggleOption(option)"
          @keydown.space.prevent="toggleOption(option)"
        >
          <CommonIcon :name="icon" size="tiny" class="shrink-0" decorative />
          {{ $t(label) }}
        </button>
      </div>
    </div>
  </div>
</template>
