<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, toRef } from 'vue'

import CommonTooltip from '#shared/components/CommonTooltip/CommonTooltip.vue'
import type { TooltipItemDescriptor } from '#shared/components/CommonTooltip/types.ts'
import useValue from '#shared/components/Form/composables/useValue.ts'
import type {
  FieldSecurityProps,
  SecurityOption,
  SecurityValue,
} from '#shared/components/Form/fields/FieldSecurity/types.ts'
import { useFieldSecurity } from '#shared/components/Form/fields/FieldSecurity/useFieldSecurity.ts'
import { useTraverseOptions } from '#shared/composables/useTraverseOptions.ts'
import { translateArticleSecurity } from '#shared/entities/ticket-article/composables/translateArticleSecurity.ts'
import { i18n } from '#shared/i18n.ts'

const props = defineProps<FieldSecurityProps>()
const contextReactive = toRef(props, 'context')

const { localValue } = useValue<SecurityValue>(contextReactive)

const {
  securityMethods,
  previewMethod,
  isCurrentSecurityOption,
  isSecurityOptionDisabled,
  changeSecurityState,
} = useFieldSecurity(contextReactive, localValue)

const options = computed(() => {
  return [
    {
      option: 'encryption',
      label: __('Encrypt'),
      icon: isCurrentSecurityOption('encryption')
        ? 'encryption-enabled'
        : 'encryption-disabled',
    },
    {
      option: 'sign',
      label: __('Sign'),
      icon: isCurrentSecurityOption('sign') ? 'sign-enabled' : 'sign-disabled',
    },
  ] as const
})

const toggleOption = (name: SecurityOption) => {
  if (isSecurityOptionDisabled(name)) return
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
</script>

<template>
  <div
    :id="context.id"
    :class="context.classes.input"
    class="flex h-auto flex-col gap-2"
    :aria-describedby="context.describedBy"
    v-bind="context.attrs"
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
        tabindex="0"
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
        <CommonIcon name="tooltip" size="small" />
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
            'bg-gray-600/50 text-white/30': isSecurityOptionDisabled(option),
            'cursor-pointer': !isSecurityOptionDisabled(option),
            'bg-gray-300 text-white': !isCurrentSecurityOption(option),
            'bg-white font-semibold text-black':
              isCurrentSecurityOption(option),
          }"
          :tabindex="isSecurityOptionDisabled(option) ? -1 : 0"
          :disabled="isSecurityOptionDisabled(option)"
          :aria-selected="isCurrentSecurityOption(option)"
          :aria-disabled="isSecurityOptionDisabled(option)"
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
