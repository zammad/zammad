<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import { type RouteLocationRaw, useRouter } from 'vue-router'

import { useForm } from '#shared/components/Form/useForm.ts'
import type { FormRef } from '#shared/components/Form/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import LayoutPublicPageBoxActions from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPageBoxActions.vue'
import type {
  ButtonType,
  ButtonVariant,
} from '#desktop/components/CommonButton/types.ts'

interface Props {
  form?: FormRef
  skipRoute?: RouteLocationRaw
  goBackRoute?: RouteLocationRaw
  onSkip?: () => void
  onBack?: () => void
  onSubmit?: () => void
  submitButtonText?: string
  submitButtonVariant?: ButtonVariant
  submitButtonType?: ButtonType
}

const props = withDefaults(defineProps<Props>(), {
  submitButtonVariant: 'submit',
  submitButtonType: 'submit',
})

const emit = defineEmits<{
  (e: 'submit'): void
  (e: 'back'): void
  (e: 'skip'): void
}>()

const router = useRouter()

const { isDisabled, formNodeId } = useForm(toRef(props, 'form'))

const localSubmitButtonText = computed(() => {
  return props.submitButtonText || __('Submit')
})

const goBack = () => {
  if (props.onBack) emit('back')

  if (props.goBackRoute) router.push(props.goBackRoute)
}

const skip = () => {
  if (props.onSkip) emit('skip')

  if (props.skipRoute) router.push(props.skipRoute)
}

const submit = () => {
  emit('submit')
}
</script>

<template>
  <LayoutPublicPageBoxActions>
    <CommonButton
      v-if="goBackRoute || onBack"
      variant="secondary"
      size="large"
      :disabled="isDisabled"
      @click="goBack()"
    >
      {{ $t('Go Back') }}
    </CommonButton>
    <CommonButton
      v-if="skipRoute || onSkip"
      variant="tertiary"
      size="large"
      :disabled="isDisabled"
      @click="skip()"
    >
      {{ $t('Skip') }}
    </CommonButton>
    <CommonButton
      v-if="form || onSubmit"
      :type="submitButtonType"
      size="large"
      :variant="submitButtonVariant"
      :disabled="isDisabled"
      :form="formNodeId"
      @click="submit()"
    >
      {{ $t(localSubmitButtonText) }}
    </CommonButton>
  </LayoutPublicPageBoxActions>
</template>
