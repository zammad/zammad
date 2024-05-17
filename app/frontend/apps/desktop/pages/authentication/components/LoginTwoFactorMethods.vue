<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import type { TwoFactorPlugin } from '#shared/entities/two-factor/types.ts'
import type { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

defineProps<{
  methods: TwoFactorPlugin[]
  defaultMethod?: Maybe<EnumTwoFactorAuthenticationMethod>
  recoveryCodesAvailable: boolean
}>()

const emit = defineEmits<{
  select: [twoFactorMethod: EnumTwoFactorAuthenticationMethod]
  cancel: []
  'use-recovery-code': []
}>()
</script>

<template>
  <section
    v-for="method of methods"
    :key="method.name"
    class="mt-3 flex flex-col"
  >
    <CommonButton
      size="large"
      block
      :prefix-icon="method.icon"
      :variant="method.name == defaultMethod ? 'primary' : 'tertiary'"
      @click="emit('select', method.name)"
    >
      {{ $t(method.label) }}
    </CommonButton>

    <div v-if="method.description" class="mt-2.5 text-center">
      <CommonLabel>
        {{ $t(method.description) }}
      </CommonLabel>
    </div>
  </section>

  <div class="mt-8 text-center text-sm">
    <CommonLink
      v-if="recoveryCodesAvailable"
      link="#"
      @click="emit('use-recovery-code')"
    >
      {{ $t('Or use one of your recovery codes.') }}
    </CommonLink>
  </div>

  <CommonButton class="mt-5" size="large" block @click="emit('cancel')">
    {{ $t('Cancel & Go Back') }}
  </CommonButton>
</template>
