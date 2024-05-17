<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'

import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import Form from '#shared/components/Form/Form.vue'
import type {
  FormSubmitData,
  FormSchemaNode,
} from '#shared/components/Form/types.ts'
import type {
  TwoFactorLoginFormData,
  LoginCredentials,
  TwoFactorPlugin,
} from '#shared/entities/two-factor/types.ts'
import UserError from '#shared/errors/UserError.ts'
import { useTwoFactorMethodInitiateAuthenticationMutation } from '#shared/graphql/mutations/twoFactorMethodInitiateAuthentication.api.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'

export interface Props {
  credentials: LoginCredentials
  twoFactor: TwoFactorPlugin
}

const props = defineProps<Props>()

const emit = defineEmits<{
  finish: []
  error: [error: UserError]
  'clear-error': []
}>()

const twoFactorLoginOptions = computed(() => props.twoFactor.loginOptions)

const schema: FormSchemaNode[] = [
  {
    type: 'text',
    name: 'code',
    label: __('Security Code'),
    required: true,
    props: {
      help: computed(() => twoFactorLoginOptions.value.helpMessage),
      autocomplete: 'one-time-code',
      autofocus: true,
      inputmode: 'numeric',
      pattern: '[0-9]*',
    },
  },
]

const authentication = useAuthenticationStore()

const loading = ref(false)
const error = ref<string | null>(null)
const canRetry = ref(true)

const login = (payload: unknown) => {
  emit('clear-error')

  const { login, password, rememberMe } = props.credentials

  return authentication
    .login({
      login,
      password,
      rememberMe,
      twoFactorAuthentication: {
        payload,
        method: props.twoFactor.name,
      },
    })
    .then(() => {
      canRetry.value = false
      emit('finish')
    })
    .catch((error: UserError) => {
      if (error instanceof UserError) {
        emit('error', error)
      }
    })
}

const tryMethod = async () => {
  if (!twoFactorLoginOptions.value.setup) return

  const initialDataMutation = new MutationHandler(
    useTwoFactorMethodInitiateAuthenticationMutation(),
  )

  emit('clear-error')

  error.value = null
  loading.value = true
  try {
    const initiated = await initialDataMutation.send({
      twoFactorMethod: props.twoFactor.name,
      password: props.credentials.password,
      login: props.credentials.login,
    })
    if (!initiated?.twoFactorMethodInitiateAuthentication?.initiationData) {
      error.value = __(
        'Two-factor authentication method could not be initiated.',
      )
      return
    }
    const result = await twoFactorLoginOptions.value.setup(
      initiated.twoFactorMethodInitiateAuthentication.initiationData,
    )
    canRetry.value = result.retry ?? true
    if (result?.success) {
      await login(result.payload)
    } else if (result?.error) {
      error.value = result.error
    }
  } catch (err) {
    if (err instanceof UserError) {
      error.value = err.errors[0].message
    }
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await tryMethod()
})
</script>

<template>
  <Form
    v-if="twoFactorLoginOptions.form !== false"
    :schema="schema"
    @submit="login(($event as FormSubmitData<TwoFactorLoginFormData>).code)"
  >
    <template #after-fields>
      <CommonButton
        type="submit"
        variant="submit"
        size="large"
        class="mt-8"
        block
        :disabled="loading"
      >
        {{ $t('Sign in') }}
      </CommonButton>
    </template>
  </Form>
  <section
    v-else-if="twoFactorLoginOptions.setup"
    class="flex flex-col items-center justify-center"
  >
    <CommonLabel
      v-if="error && twoFactorLoginOptions.errorHelpMessage"
      class="mt-5"
    >
      {{ $t(twoFactorLoginOptions.errorHelpMessage) }}
    </CommonLabel>

    <CommonLabel v-else-if="twoFactorLoginOptions.helpMessage" class="mt-5">
      {{ $t(twoFactorLoginOptions.helpMessage) }}
    </CommonLabel>

    <CommonLoader class="mb-3 mt-8" :loading="loading" :error="error" />

    <CommonButton
      v-if="!loading && canRetry"
      size="large"
      variant="primary"
      class="mt-5"
      block
      @click="tryMethod"
    >
      {{ $t('Retry') }}
    </CommonButton>
  </section>
</template>
