<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRouter } from 'vue-router'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useApplicationConfigTwoFactor } from '#shared/composables/authentication/useApplicationConfigTwoFactor.ts'
import type { TwoFactorActionTypes } from '#shared/entities/two-factor/types.ts'
import { useUserCurrentTwoFactorRemoveMethodMutation } from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorRemoveMethod.api.ts'
import { useUserCurrentTwoFactorSetDefaultMethodMutation } from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorSetDefaultMethod.api.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import type { TwoFactorConfigurationType } from '#desktop/components/TwoFactor/types.ts'
import { useConfigurationTwoFactor } from '#desktop/entities/two-factor-configuration/composables/useConfigurationTwoFactor.ts'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'

defineOptions({
  beforeRouteEnter() {
    const { hasEnabledMethods } = useApplicationConfigTwoFactor()

    if (!hasEnabledMethods.value) return '/error'

    return true
  },
})

const session = useSessionStore()
const router = useRouter()
const { notify } = useNotifications()

const {
  hasEnabledMethods,
  hasEnabledRecoveryCodes,
  hasConfiguredMethods,
  hasRecoveryCodes,
  twoFactorConfigurationMethods,
} = useConfigurationTwoFactor()

watch(hasEnabledMethods, (newValue) => {
  if (newValue) return

  router.replace('/error')
})

const { breadcrumbItems } = useBreadcrumb(__('Two-factor Authentication'))

const twoFactorConfigurationFlyout = useFlyout({
  name: 'two-factor-flyout',
  component: () =>
    import('#desktop/components/TwoFactor/TwoFactorConfigurationFlyout.vue'),
})

const openTwoFactorConfigurationFlyout = async (
  type: TwoFactorConfigurationType,
) => {
  return twoFactorConfigurationFlyout.open({
    type,
  })
}

const setDefaultTwoFactorMethod = new MutationHandler(
  useUserCurrentTwoFactorSetDefaultMethodMutation(),
  {
    errorNotificationMessage: __(
      'Could not set two-factor authentication method as default',
    ),
  },
)

const submitTwoFactorDefaultMethod = (entity?: ObjectLike) => {
  if (!entity) return

  setDefaultTwoFactorMethod
    .send({
      methodName: entity.name,
    })
    .then(() => {
      session.setUserPreference('two_factor_authentication', {
        ...(session.user?.preferences?.two_factor_authentication || {}),
        default: entity.name,
      })

      notify({
        id: 'two-factor-method-set-default',
        type: NotificationTypes.Success,
        message: __('Two-factor authentication method was set as default.'),
      })
    })
}

const removeTwoFactorMethod = new MutationHandler(
  useUserCurrentTwoFactorRemoveMethodMutation(),
  {
    errorNotificationMessage: __(
      'Could not remove two-factor authentication method.',
    ),
  },
)

const submitTwoFactorMethodRemoval = async (entity?: ObjectLike) => {
  if (!entity) return

  return twoFactorConfigurationFlyout.open({
    type: 'removal_confirmation',
    successCallback: async () => {
      const data = await removeTwoFactorMethod.send({
        methodName: entity.name,
      })

      if (data?.userCurrentTwoFactorRemoveMethod?.success) {
        notify({
          id: 'two-factor-method-removed',
          type: NotificationTypes.Success,
          message: __('Two-factor authentication method was removed.'),
        })
      }
    },
  })
}

const lookUpA11yActionLabel = (
  entity: ObjectLike,
  type: TwoFactorActionTypes,
) => {
  const authenticatorMethod = twoFactorConfigurationMethods.value.find(
    (method) => method.name === entity.name,
  )

  return (
    authenticatorMethod?.configurationOptions?.getActionA11yLabel(type) || ''
  )
}

const actions = computed<MenuItem[]>(() => [
  {
    key: 'setup',
    label: __('Set up'),
    ariaLabel: (entity) => lookUpA11yActionLabel(entity!, 'setup'),
    icon: 'wrench',
    show: (entity) => !entity?.configured,
    onClick: (entity) => openTwoFactorConfigurationFlyout(entity?.name),
  },
  {
    key: 'edit',
    label: __('Edit'),
    ariaLabel: (entity) => lookUpA11yActionLabel(entity!, 'edit'),
    icon: 'pencil',
    show: (entity) => {
      return Boolean(
        entity?.configured && entity?.configurationOptions.editable,
      )
    },
    onClick: (entity) => openTwoFactorConfigurationFlyout(entity?.name),
  },
  {
    key: 'setAsDefault',
    label: __('Set as default'),
    ariaLabel: (entity) => lookUpA11yActionLabel(entity!, 'default'),
    icon: 'arrow-repeat',
    show: (entity) => Boolean(entity?.configured && !entity?.default),
    onClick: (entity) => submitTwoFactorDefaultMethod(entity),
  },
  {
    key: 'remove',
    label: __('Remove'),
    ariaLabel: (entity) => lookUpA11yActionLabel(entity!, 'remove'),
    icon: 'trash3',
    variant: 'danger',
    show: (entity) => Boolean(entity?.configured),
    onClick: (entity) => submitTwoFactorMethodRemoval(entity),
  },
])
</script>

<template>
  <LayoutContent :breadcrumb-items="breadcrumbItems" width="narrow">
    <div class="flex flex-col gap-2.5">
      <div>
        <CommonLabel class="mb-1.5">{{ $t('Available methods') }}</CommonLabel>
        <div class="flex flex-col rounded-lg bg-blue-200 p-1 dark:bg-gray-700">
          <div
            v-for="twoFactorMethod in twoFactorConfigurationMethods"
            :key="twoFactorMethod.name"
            class="flex items-start gap-1.5 p-2.5"
          >
            <CommonIcon
              class="text-stone-200 dark:text-neutral-500"
              :name="twoFactorMethod.icon"
              size="small"
            />
            <div class="flex grow flex-col gap-0.5">
              <div class="flex grow gap-1.5">
                <CommonLabel class="text-black dark:text-white"
                  >{{ $t(twoFactorMethod.label) }}
                </CommonLabel>
                <CommonBadge
                  v-if="twoFactorMethod.configured"
                  variant="success"
                >
                  {{ $t('Active') }}
                </CommonBadge>
                <CommonBadge v-if="twoFactorMethod.default" variant="info"
                  >{{ $t('Default') }}
                </CommonBadge>
              </div>
              <CommonLabel
                v-if="twoFactorMethod.description"
                class="text-stone-200 dark:text-neutral-500"
                size="small"
                >{{ $t(twoFactorMethod.description) }}
              </CommonLabel>
            </div>
            <CommonActionMenu
              :entity="twoFactorMethod"
              :custom-menu-button-label="
                twoFactorMethod.configurationOptions?.actionButtonA11yLabel
              "
              :actions="actions"
            />
          </div>
        </div>
      </div>
      <template v-if="hasConfiguredMethods && hasEnabledRecoveryCodes">
        <CommonLabel
          >{{
            $t(
              'Recovery codes can be used to access your account in the event you lose access to other two-factor authentication methods.',
            )
          }}
        </CommonLabel>
        <CommonLabel v-if="hasRecoveryCodes"
          >{{
            $t(
              "If you lose your recovery codes it's possible to generate new ones. This action is going to invalidate previous recovery codes.",
            )
          }}
        </CommonLabel>
        <div class="flex justify-end">
          <CommonButton
            variant="submit"
            type="submit"
            size="medium"
            @click="openTwoFactorConfigurationFlyout('recovery_codes')"
          >
            {{
              hasRecoveryCodes
                ? $t('Regenerate Recovery Codes')
                : $t('Generate Recovery Codes')
            }}
          </CommonButton>
        </div>
      </template>
    </div>
  </LayoutContent>
</template>
