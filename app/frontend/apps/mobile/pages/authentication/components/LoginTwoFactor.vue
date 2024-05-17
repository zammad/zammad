<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import Form from '#shared/components/Form/Form.vue'
import type {
  FormSubmitData,
  FormSchemaNode,
} from '#shared/components/Form/types.ts'
import type {
  TwoFactorLoginFormData,
  TwoFactorPlugin,
  LoginCredentials,
} from '#shared/entities/two-factor/types.ts'
import UserError from '#shared/errors/UserError.ts'
import { useTwoFactorMethodInitiateAuthenticationMutation } from '#shared/graphql/mutations/twoFactorMethodInitiateAuthentication.api.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'

export interface Props {
  credentials: LoginCredentials
  twoFactor: TwoFactorPlugin
}

const props = defineProps<Props>()

const emit = defineEmits<{
  finish: []
  error: [UserError]
}>()

const twoFactorLoginOptions = computed(() => props.twoFactor.loginOptions)

const schema: FormSchemaNode[] = [
  {
    isLayout: true,
    component: 'FormGroup',
    props: {
      help: computed(() => twoFactorLoginOptions.value.helpMessage),
    },
    children: [
      {
        type: 'text',
        name: 'code',
        label: __('Security Code'),
        required: true,
        props: {
          autocomplete: 'one-time-code',
          autofocus: true,
          inputmode: 'numeric',
          pattern: '[0-9]*',
        },
      },
    ],
  },
]

const { clearAllNotifications } = useNotifications()
const authentication = useAuthenticationStore()

const loading = ref(false)
const error = ref<string | null>(null)
const canRetry = ref(true)

const login = (payload: unknown) => {
  clearAllNotifications()
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
      <FormKit
        wrapper-class="mt-6 flex grow justify-center items-center"
        input-class="py-2 px-4 w-full h-14 text-xl rounded-xl select-none"
        variant="submit"
        type="submit"
      >
        {{ $t('Sign in') }}
      </FormKit>
    </template>
  </Form>
  <section
    v-else-if="twoFactorLoginOptions.setup"
    class="flex flex-col items-center justify-center"
  >
    <CommonLoader :loading="loading" :error="error" />

    <div class="text-gray pb-2 pt-2 font-medium leading-4">
      <template v-if="error && twoFactorLoginOptions.errorHelpMessage">
        {{ $t(twoFactorLoginOptions.errorHelpMessage) }}
      </template>
      <template v-else-if="twoFactorLoginOptions.helpMessage">
        {{ $t(twoFactorLoginOptions.helpMessage) }}
      </template>
    </div>

    <CommonButton
      v-if="!loading && canRetry"
      variant="primary"
      class="mt-3 px-5 py-2 text-base"
      @click="tryMethod"
    >
      {{ $t('Retry') }}
    </CommonButton>
  </section>
</template>
