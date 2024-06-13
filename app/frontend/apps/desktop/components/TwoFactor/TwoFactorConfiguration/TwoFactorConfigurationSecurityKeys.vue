<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import Form from '#shared/components/Form/Form.vue'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useTwoFactorPlugins } from '#shared/entities/two-factor/composables/useTwoFactorPlugins.ts'
import type { TwoFactorSetupResult } from '#shared/entities/two-factor/types.ts'
import { useUserCurrentTwoFactorGetMethodConfigurationQuery } from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorGetMethodConfiguration.api.ts'
import { useUserCurrentTwoFactorRemoveMethodCredentialsMutation } from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorRemoveMethodCredentials.api.ts'
import { useUserCurrentTwoFactorVerifyMethodConfigurationMutation } from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorVerifyMethodConfiguration.api.ts'
import { useUserCurrentTwoFactorInitiateMethodConfigurationLazyQuery } from '#shared/entities/user/current/graphql/queries/two-factor/userCurrentTwoFactorInitiateMethodConfiguration.api.ts'
import UserError from '#shared/errors/UserError.ts'
import {
  MutationHandler,
  QueryHandler,
} from '#shared/server/apollo/handler/index.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSimpleTable from '#desktop/components/CommonSimpleTable/CommonSimpleTable.vue'
import type { TableHeader } from '#desktop/components/CommonSimpleTable/types.ts'

import type { TwoFactorConfigurationComponentProps } from '../types.ts'

const props = defineProps<TwoFactorConfigurationComponentProps>()

const { twoFactorMethodLookup } = useTwoFactorPlugins()

const twoFactorPlugin = twoFactorMethodLookup[props.type]

const headerSubtitle = computed(() => {
  return twoFactorPlugin.label
})

const headerIcon = computed(() => {
  return twoFactorPlugin.icon
})

const { isValid, form, formSubmit, waitForFormSettled } = useForm()

const state = ref<'overview' | 'config' | 'register' | 'retry'>('overview')

const footerActionOptions = computed(() => {
  let actionLabel
  let disabled = false
  let variant

  switch (state.value) {
    case 'config':
      actionLabel = __('Next')
      variant = 'primary'
      break
    case 'register':
      actionLabel = __('Set Up')
      disabled = true
      break
    case 'retry':
      actionLabel = __('Retry')
      variant = 'primary'
      break
    case 'overview':
    default:
      actionLabel = __('Set Up')
      variant = 'submit'
  }
  return {
    actionLabel,
    actionButton: { variant, disabled },
    cancelButton: { disabled },
  }
})

const configurationQuery = new QueryHandler(
  useUserCurrentTwoFactorGetMethodConfigurationQuery({
    methodName: twoFactorPlugin.name,
  }),
  {
    errorNotificationMessage: __('Could not fetch security keys'),
  },
)

const configuration = computed<ObjectLike>(
  () =>
    configurationQuery.result().value
      ?.userCurrentTwoFactorGetMethodConfiguration,
)

const credentials = computed<ObjectLike[]>(
  () => configuration.value?.credentials || [],
)

const tableHeaders: TableHeader[] = [
  {
    key: 'nickname',
    label: __('Name'),
    truncate: true,
  },
  {
    key: 'created_at',
    label: __('Created at'),
    type: 'timestamp',
  },
]

const tableItems = computed(() =>
  credentials.value.map((credential) => ({
    id: credential.public_key,
    nickname: credential.nickname,
    created_at: credential.created_at,
  })),
)

const { notify } = useNotifications()

const removeCredentialsMutation = new MutationHandler(
  useUserCurrentTwoFactorRemoveMethodCredentialsMutation(),
  {
    errorNotificationMessage: __(
      'Could not remove two-factor authentication method.',
    ),
  },
)

const tableActions: MenuItem[] = [
  {
    key: 'remove',
    label: __('Remove'),
    icon: 'trash3',
    variant: 'danger',
    onClick: async (entity) => {
      if (!entity?.id) return

      const removeCredentialsResult = await removeCredentialsMutation.send({
        methodName: twoFactorPlugin.name,
        credentialId: entity.id,
      })

      if (
        !removeCredentialsResult?.userCurrentTwoFactorRemoveMethodCredentials
          ?.success
      )
        return

      await configurationQuery.refetch()

      props.successCallback?.()

      notify({
        id: 'two-factor-method-removed',
        type: NotificationTypes.Success,
        message: __('Two-factor authentication method was removed.'),
      })
    },
  },
]

const nickname = ref('')
const loading = ref(false)
const error = ref<string | null>(null)

const initiateQuery = new QueryHandler(
  useUserCurrentTwoFactorInitiateMethodConfigurationLazyQuery(
    {
      methodName: twoFactorPlugin.name,
    },
    {
      fetchPolicy: 'no-cache',
    },
  ),
)

const setupCredential = async () => {
  const initiateQueryResult = await initiateQuery.query({
    variables: {
      methodName: twoFactorPlugin.name,
    },
  })

  const initiateData =
    initiateQueryResult.data?.userCurrentTwoFactorInitiateMethodConfiguration

  if (!initiateData)
    throw new Error(
      __('Two-factor authentication method could not be initiated.'),
    )

  return {
    initiateData,
    setupResult:
      await twoFactorPlugin.configurationOptions?.setup?.(initiateData),
  }
}

const verifyMutation = new MutationHandler(
  useUserCurrentTwoFactorVerifyMethodConfigurationMutation(),
)

const verifyCredential = async (
  initiateData: ObjectLike,
  setupResult: TwoFactorSetupResult,
) => {
  const verifyResult = (
    await verifyMutation.send({
      methodName: twoFactorPlugin.name,
      payload: setupResult.payload,
      configuration: {
        ...initiateData,
        nickname: nickname.value,
        type: 'registration',
      },
    })
  )?.userCurrentTwoFactorVerifyMethodConfiguration

  return verifyResult
}

const configureCredential = async () => {
  if (!twoFactorPlugin.configurationOptions?.setup) return

  error.value = null
  loading.value = true

  try {
    const { initiateData, setupResult } = await setupCredential()

    if (setupResult?.success) {
      const verifyResult = await verifyCredential(initiateData, setupResult)
      return Promise.resolve({ recoveryCodes: verifyResult?.recoveryCodes })
    }

    if (setupResult?.error) {
      error.value = setupResult.error
      if (setupResult.retry ?? true) state.value = 'retry'
      return Promise.reject()
    }
  } catch (err) {
    if (err instanceof UserError) {
      error.value = err.errors[0].message
    } else if (err instanceof Error) {
      error.value = err.message
    } else {
      error.value = __('Two-factor method could not be configured.')
    }
    state.value = 'retry'
    return Promise.reject()
  } finally {
    loading.value = false
  }
}

const registerCredential = async () => {
  state.value = 'register'

  const result = await configureCredential()

  if (error.value) return Promise.reject()

  props.successCallback?.()

  if (result?.recoveryCodes)
    return Promise.resolve({
      nextState: 'recovery_codes',
      options: {
        ...result,
        headerIcon: headerIcon.value,
      },
    })

  notify({
    id: 'two-factor-method-added',
    type: NotificationTypes.Success,
    message: __('Two-factor authentication method was set up successfully.'),
  })

  return Promise.resolve({})
}

const submitForm = async () => {
  const result = await registerCredential()

  if (!result) return

  props.formSubmitCallback?.(result)
}

const submitFormManual = async () => {
  formSubmit()

  await waitForFormSettled()

  if (!isValid.value) return Promise.reject()

  return registerCredential()
}

const executeAction = async () => {
  let result

  switch (state.value) {
    case 'config':
      result = await submitFormManual()
      break
    case 'retry':
      result = await registerCredential()
      break
    case 'register':
      break
    case 'overview':
    default:
      state.value = 'config'
      break
  }

  if (!result) return Promise.reject()

  return Promise.resolve(result)
}

defineExpose({
  executeAction,
  headerSubtitle,
  headerIcon,
  footerActionOptions,
})
</script>

<template>
  <div class="flex flex-col gap-3">
    <template v-if="state === 'overview'">
      <CommonLoader
        v-if="configurationQuery.loading().value"
        class="my-3"
        :loading="Boolean(configurationQuery.loading().value)"
      />
      <template v-else>
        <CommonLabel>{{
          $t(
            'Security keys are hardware or software credentials that can be used as your two-factor authentication method.',
          )
        }}</CommonLabel>
        <CommonSimpleTable
          v-if="tableItems.length"
          :headers="tableHeaders"
          :items="tableItems"
          :actions="tableActions"
        />
        <CommonLabel>{{
          $t(
            'To register a new security key with your account, press the button below.',
          )
        }}</CommonLabel>
      </template>
    </template>
    <template v-else-if="state === 'config'">
      <Form ref="form" @submit="submitForm">
        <FormKit
          v-model="nickname"
          type="text"
          name="nickname"
          maxlength="255"
          :label="$t('Name for this security key')"
          validation="required"
        />
      </Form>
    </template>
    <template v-else-if="state === 'register' || state === 'retry'">
      <CommonLabel
        v-if="state === 'register' && loading"
        class="mx-auto my-3"
        >{{ $t('Getting key information from the browser…') }}</CommonLabel
      >
      <CommonLoader class="my-3" :loading="loading" :error="error" />
    </template>
  </div>
</template>
