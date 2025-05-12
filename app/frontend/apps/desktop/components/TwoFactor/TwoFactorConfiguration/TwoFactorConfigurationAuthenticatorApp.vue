<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import QRCode from 'qrcode'
import { computed, ref, useTemplateRef } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'
import { useTwoFactorPlugins } from '#shared/entities/two-factor/composables/useTwoFactorPlugins.ts'
import { useUserCurrentTwoFactorVerifyMethodConfigurationMutation } from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorVerifyMethodConfiguration.api.ts'
import { useUserCurrentTwoFactorInitiateMethodConfigurationQuery } from '#shared/entities/user/current/graphql/queries/two-factor/userCurrentTwoFactorInitiateMethodConfiguration.api.ts'
import UserError from '#shared/errors/UserError.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { usePasswordCheckTwoFactor } from '#desktop/entities/two-factor-configuration/composables/usePasswordCheckTwoFactor.ts'

import type { TwoFactorConfigurationComponentPropsWithRequiredToken } from '../types.ts'
import type { ApolloError } from '@apollo/client/errors'

const props =
  defineProps<TwoFactorConfigurationComponentPropsWithRequiredToken>()

const { twoFactorMethodLookup } = useTwoFactorPlugins()
const twoFactorPlugin = twoFactorMethodLookup[props.type]

const headerIcon = computed(() => twoFactorPlugin.icon)

const initiationQuery = new QueryHandler(
  useUserCurrentTwoFactorInitiateMethodConfigurationQuery(
    {
      methodName: twoFactorPlugin.name,
      token: props.token,
    },
    {
      fetchPolicy: 'no-cache',
    },
  ),
)

const { redirectToPasswordCheck } = usePasswordCheckTwoFactor(
  props.formSubmitCallback,
)

initiationQuery.onError((error: ApolloError) => {
  if (
    error?.graphQLErrors?.[0]?.extensions?.type !==
    'Gql::Concerns::HandlesPasswordRevalidationToken::InvalidTokenError'
  )
    return

  redirectToPasswordCheck()
})

const initiationResult = initiationQuery.result()

const { notify } = useNotifications()

const canvasElement = useTemplateRef('canvas')
const showSecretOverlay = ref(false)
const initiationError = ref<string | null>(null)

// Form handling
const { form, formSetErrors } = useForm()

const mutateMethodConfiguration = new MutationHandler(
  useUserCurrentTwoFactorVerifyMethodConfigurationMutation(),
  {
    errorShowNotification: false,
    errorCallback: (error) => {
      if (error.type === GraphQLErrorTypes.UnknownError) {
        redirectToPasswordCheck()
        return false
      }

      return true
    },
  },
)

const verifyMethodConfiguration = async (securityCode: string) => {
  // TODO: Redirect to the password check step.
  if (!props.token) return

  return mutateMethodConfiguration.send({
    methodName: twoFactorPlugin.name,
    token: props.token,
    payload: securityCode,
    configuration: {
      ...initiationResult.value
        ?.userCurrentTwoFactorInitiateMethodConfiguration,
    },
  })
}

const submitForm = async ({
  securityCode,
}: FormSubmitData<{ securityCode: string }>) => {
  try {
    const response = await verifyMethodConfiguration(securityCode)

    props.successCallback?.()

    notify({
      id: 'two-factor-method-configured',
      type: NotificationTypes.Success,
      message: __('Two-factor method has been configured successfully.'),
    })

    if (
      response?.userCurrentTwoFactorVerifyMethodConfiguration?.recoveryCodes
    ) {
      props.formSubmitCallback?.({
        nextState: 'recovery_codes',
        options: {
          recoveryCodes:
            response?.userCurrentTwoFactorVerifyMethodConfiguration
              ?.recoveryCodes,
          headerIcon: headerIcon.value,
        },
      })
      return
    }

    props.formSubmitCallback?.({})
  } catch (error) {
    if (error instanceof UserError) {
      formSetErrors(
        new UserError([
          {
            field: 'securityCode',
            message: __(
              'Invalid security code! Please try again with a new code.',
            ),
          },
        ]),
      )
    }
  }
}

// Flyout configuration
const authenticatorApps = [
  {
    label: __('Google Authenticator'),
    key: 'google-authenticator',
    link: 'https://support.google.com/accounts/answer/1066447',
  },
  {
    label: __('Authy'),
    key: 'authy',
    link: 'https://support.authy.com/hc/en-us/articles/115001945848-Installing-Authy-apps/',
  },
  {
    label: __('Microsoft Authenticator'),
    key: 'microsoft-authenticator',
    link: 'https://support.microsoft.com/en-us/account-billing/download-and-install-the-microsoft-authenticator-app-351498fc-850a-45da-b7b6-27e523b8702a',
  },
]

const footerActionOptions = computed(() => ({
  actionLabel: __('Set Up'),
  actionButton: { variant: 'submit', type: 'submit' },
}))

const { copyToClipboard } = useCopyToClipboard()

const toggleSecretCodeOverlay = () => {
  showSecretOverlay.value = !showSecretOverlay.value
}

// Set up QR code
const secretCode = ref<string | null>(null)
const loading = ref(true)

const setupQrCode = async (provisioningUri: string, secret: string) => {
  secretCode.value = secret

  return QRCode.toCanvas(canvasElement.value, provisioningUri, {
    margin: 1,
    width: 307,
  })
}

initiationQuery.onResult(({ data }) => {
  if (data?.userCurrentTwoFactorInitiateMethodConfiguration) {
    // eslint-disable-next-line camelcase
    const { provisioning_uri, secret } =
      // eslint-disable-next-line no-unsafe-optional-chaining
      data?.userCurrentTwoFactorInitiateMethodConfiguration

    setupQrCode(provisioning_uri, secret)
      .catch(() => {
        initiationError.value = __(
          'Failed to set up QR code. Please try again.',
        )
      })
      .finally(() => {
        loading.value = false
      })
  }
})

defineExpose({
  headerSubtitle: computed(() => twoFactorPlugin.label),
  headerIcon: headerIcon.value,
  form,
  footerActionOptions,
})
</script>

<template>
  <CommonLoader :loading="loading" :error="initiationError" />
  <div
    v-show="!loading"
    class="space-y-2 text-sm text-gray-100 dark:text-neutral-400"
  >
    <CommonLabel
      >{{
        $t(
          'To set up Authenticator App for your account, follow the steps below:',
        )
      }}
    </CommonLabel>
    <ol class="list-decimal space-y-3 ltr:pl-4 rtl:pr-4">
      <li>
        <CommonLabel class="mb-2"
          >{{
            $t(
              'Unless you already have it, install one of the following authenticator apps on your mobile device:',
            )
          }}
        </CommonLabel>
        <ul class="list-disc ltr:pl-5 rtl:pr-5">
          <li v-for="app in authenticatorApps" :key="app.key">
            <CommonLink external :link="app.link" open-in-new-tab>
              {{ $t(app.label) }}
            </CommonLink>
          </li>
        </ul>
      </li>

      <li>
        <CommonLabel class="mb-2"
          >{{ $t('Open your authenticator app and scan the QR code below:') }}
        </CommonLabel>
        <div
          tabindex="0"
          role="button"
          aria-haspopup="true"
          data-test-id="secret-overlay"
          aria-controls="qr-code-secret-overlay"
          class="relative mx-auto w-fit cursor-pointer rounded-lg hover:outline hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 focus:outline focus:outline-1 focus:outline-offset-1 focus:outline-blue-800 has-[button:hover,span:hover]:outline-0 dark:hover:outline-blue-900"
          @click="toggleSecretCodeOverlay"
          @keydown.enter="toggleSecretCodeOverlay"
        >
          <canvas
            ref="canvas"
            class="rounded-lg"
            role="img"
            :aria-label="$t('Authenticator app QR code')"
          />
          <Transition name="fade">
            <div
              v-show="showSecretOverlay"
              id="qr-code-secret-overlay"
              class="bg-opacity-90 absolute top-0 right-0 bottom-0 left-0 flex flex-col items-center justify-center gap-1.5 rounded-lg bg-black"
              role="presentation"
            >
              <span
                class="cursor-text font-mono text-white"
                :aria-label="$t('Authenticator app secret')"
                @click.stop
              >
                {{ secretCode }}
              </span>
              <CommonButton
                prefix-icon="files"
                size="medium"
                @click.stop="copyToClipboard(secretCode)"
                >{{ $t('Copy Secret') }}</CommonButton
              >
            </div>
          </Transition>
        </div>
      </li>

      <li>
        <CommonLabel id="security-code-description" class="mb-2">{{
          $t('Enter the security code generated by the authenticator app:')
        }}</CommonLabel>

        <Form
          ref="form"
          should-autofocus
          @submit="
            submitForm($event as FormSubmitData<{ securityCode: string }>)
          "
        >
          <FormKit
            name="securityCode"
            type="text"
            :placeholder="$t('Security Code')"
            aria-labelledby="security-code-description"
            validation="required"
          />
        </Form>
      </li>

      <li>
        <CommonLabel>{{
          $t('Press the button below to finish the setup.')
        }}</CommonLabel>
      </li>
    </ol>
  </div>
</template>
