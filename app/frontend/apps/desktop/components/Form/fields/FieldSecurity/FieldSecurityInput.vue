<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import { EnumSecurityStateType } from '#shared/components/Form/fields/FieldSecurity/types.ts'
import type {
  FieldSecurityProps,
  SecurityOption,
  SecurityValue,
} from '#shared/components/Form/fields/FieldSecurity/types.ts'
import { useFieldSecurity } from '#shared/components/Form/fields/FieldSecurity/useFieldSecurity.ts'
import { translateArticleSecurity } from '#shared/entities/ticket-article/composables/translateArticleSecurity.ts'
import { i18n } from '#shared/i18n.ts'

import CommonTabGroup from '#desktop/components/CommonTabGroup/CommonTabGroup.vue'
import type { Tab } from '#desktop/components/CommonTabGroup/types.ts'

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

const securityMethodTabs = computed(() =>
  securityMethods.value.map((securityMethod) => ({
    key: securityMethod,
    label: translateArticleSecurity(securityMethod),
  })),
)

const getTooltipText = (option: SecurityOption) => {
  const { message, messagePlaceholder } =
    props.context.securityMessages?.[previewMethod.value]?.[option] || {}

  return i18n.t(message, ...(messagePlaceholder || []))
}

const optionTabs = computed(() => [
  {
    key: 'encryption' as SecurityOption,
    label: __('Encrypt'),
    icon: isCurrentSecurityOption('encryption')
      ? 'encryption-enabled'
      : 'encryption-disabled',
    tooltip: getTooltipText('encryption'),
    disabled: isSecurityOptionDisabled('encryption'),
  },
  {
    key: 'sign' as SecurityOption,
    label: __('Sign'),
    icon: isCurrentSecurityOption('sign') ? 'sign-enabled' : 'sign-disabled',
    tooltip: getTooltipText('sign'),
    disabled: isSecurityOptionDisabled('sign'),
  },
])

const selectedOptionTabs = computed(() =>
  optionTabs.value
    .filter((optionTab) => isCurrentSecurityOption(optionTab.key))
    .map((optionTab) => optionTab.key),
)

const selectOption = (value: Tab['key'] | Tab['key'][]) => {
  const options = (value as SecurityOption[]).sort()

  localValue.value = {
    method: previewMethod.value,
    options,
  }
}
</script>

<template>
  <div
    :id="context.id"
    :class="context.classes.input"
    class="flex h-auto flex-col gap-2"
    :aria-describedby="context.describedBy"
    v-bind="context.attrs"
  >
    <div class="flex gap-2">
      <CommonTabGroup
        v-if="securityMethods.length > 1"
        :model-value="previewMethod"
        :tabs="securityMethodTabs"
        size="medium"
        @update:model-value="
          changeSecurityState($event as EnumSecurityStateType)
        "
      />
      <CommonTabGroup
        :model-value="selectedOptionTabs"
        :tabs="optionTabs"
        size="medium"
        multiple
        @update:model-value="selectOption"
      />
    </div>
  </div>
</template>
