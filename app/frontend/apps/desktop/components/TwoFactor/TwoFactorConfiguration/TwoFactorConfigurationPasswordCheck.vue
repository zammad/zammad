<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useTwoFactorPlugins } from '#shared/entities/two-factor/composables/useTwoFactorPlugins.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import { useUserCurrentPasswordCheckMutation } from '#desktop/entities/user/current/graphql/mutations/userCurrentPasswordCheck.api.ts'

import type { TwoFactorConfigurationComponentProps } from '../types.ts'

const props = defineProps<TwoFactorConfigurationComponentProps>()

const { form } = useForm()

const schema = defineFormSchema([
  {
    name: 'password',
    label: __('Current password'),
    type: 'password',
    props: {
      maxLength: 100,
      autocomplete: 'password',
    },
    required: true,
  },
])

const passwordCheckMutation = new MutationHandler(
  useUserCurrentPasswordCheckMutation(),
  {
    errorNotificationMessage: __('Password could not be checked'),
  },
)

const headerSubtitle = __('Confirm Password')

const { twoFactorMethodLookup } = useTwoFactorPlugins()

const headerIcon = computed(() => {
  switch (props.type) {
    case 'recovery_codes':
      return 'shield-lock'
    case 'removal_confirmation':
      return 'trash3'
    default:
      return twoFactorMethodLookup[props.type]?.icon
  }
})

const footerActionOptions = computed(() => {
  let actionLabel = __('Next')
  let variant = 'primary'
  let cancelLabel

  if (props.type === 'removal_confirmation') {
    actionLabel = __('Remove')
    variant = 'danger'
  }

  if (props.type === 'method_list') cancelLabel = __('Cancel & Sign Out')

  return {
    actionLabel,
    actionButton: { variant, type: 'submit' },
    cancelLabel,
  }
})

const submitForm = async (formData: FormSubmitData<Record<string, string>>) => {
  return passwordCheckMutation
    .send({ password: formData.password })
    .then((data) => {
      if (
        !data?.userCurrentPasswordCheck?.success ||
        !data?.userCurrentPasswordCheck?.token
      )
        return

      if (props.type === 'removal_confirmation') {
        props.successCallback?.({
          token: data.userCurrentPasswordCheck.token,
        })

        props.formSubmitCallback?.({})

        return
      }

      props.formSubmitCallback?.({
        nextState: props.type,
        token: data.userCurrentPasswordCheck.token,
      })
    })
}

defineExpose({
  headerSubtitle,
  headerIcon,
  footerActionOptions,
  form,
})
</script>

<template>
  <Form
    ref="form"
    :schema="schema"
    should-autofocus
    @submit="submitForm($event as FormSubmitData<Record<string, string>>)"
  />
</template>
