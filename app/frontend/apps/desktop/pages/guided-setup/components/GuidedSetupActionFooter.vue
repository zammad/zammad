<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import { type RouteLocationRaw, useRouter } from 'vue-router'

import type { FormRef } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type {
  ButtonType,
  ButtonVariant,
} from '#desktop/components/CommonButton/types.ts'
import LayoutPublicPageBoxActions from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPageBoxActions.vue'

interface Props {
  form?: FormRef
  skipRoute?: RouteLocationRaw
  continueRoute?: RouteLocationRaw
  goBackRoute?: RouteLocationRaw
  onSkip?: () => void
  onContinue?: () => void
  onGoBack?: () => void
  onSubmit?: () => void
  submitButtonText?: string
  submitButtonVariant?: ButtonVariant
  submitButtonType?: ButtonType
  continueButtonText?: string
}

const props = withDefaults(defineProps<Props>(), {
  submitButtonVariant: 'submit',
  submitButtonType: 'submit',
})

const emit = defineEmits<{
  submit: []
  'go-back': []
  skip: []
  continue: []
}>()

const router = useRouter()

const { isDisabled, formNodeId } = useForm(toRef(props, 'form'))

const localContinueButtonText = computed(() => {
  return props.continueButtonText || __('Continue')
})

const localSubmitButtonText = computed(() => {
  return props.submitButtonText || __('Submit')
})

const goBack = () => {
  if (props.onGoBack) emit('go-back')

  if (props.goBackRoute) router.push(props.goBackRoute)
}

const skip = () => {
  if (props.onSkip) emit('skip')

  if (props.skipRoute) router.push(props.skipRoute)
}

const cont = () => {
  if (props.onContinue) emit('continue')

  if (props.continueRoute) router.push(props.continueRoute)
}

const submit = () => {
  emit('submit')
}
</script>

<template>
  <LayoutPublicPageBoxActions>
    <CommonButton
      v-if="goBackRoute || onGoBack"
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
      v-if="continueRoute || onContinue"
      variant="primary"
      size="large"
      :disabled="isDisabled"
      @click="cont()"
    >
      {{ $t(localContinueButtonText) }}
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
