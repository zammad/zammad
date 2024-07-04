<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, ref } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useThirdPartyAuthentication } from '#shared/composables/authentication/useThirdPartyAuthentication.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import useFingerprint from '#shared/composables/useFingerprint.ts'
import {
  type Authorization,
  EnumAuthenticationProvider,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSimpleTable from '#desktop/components/CommonSimpleTable/CommonSimpleTable.vue'
import type {
  TableHeader,
  TableItem,
} from '#desktop/components/CommonSimpleTable/types.ts'
import CommonThirdPartyAuthenticationButton from '#desktop/components/CommonThirdPartyAuthenticationButton/CommonThirdPartyAuthenticationButton.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useBreadcrumb } from '#desktop/pages/personal-setting/composables/useBreadcrumb.ts'
import { useUserCurrentRemoveLinkedAccountMutation } from '#desktop/pages/personal-setting/graphql/mutations/userCurrentLinkedAccount.api.ts'
import type { LinkedAccountTableItem } from '#desktop/pages/personal-setting/types/linked-accounts.ts'

defineOptions({
  beforeRouteEnter() {
    const { hasEnabledProviders } = useThirdPartyAuthentication()

    if (!hasEnabledProviders.value) return '/error'

    return true
  },
})

const { notify } = useNotifications()
const { breadcrumbItems } = useBreadcrumb(__('Linked Accounts'))

const { user } = storeToRefs(useSessionStore())

const { enabledProviders } = useThirdPartyAuthentication()
const { fingerprint } = useFingerprint()

const providersLookup = computed(() => {
  if (!user.value?.authorizations) return []

  const { authorizations } = user.value

  return enabledProviders.value.map((enabledProvider) => {
    const configuredProvider = authorizations.find(
      ({ provider }) => provider === enabledProvider.name,
    )
    return {
      ...enabledProvider,
      uid: configuredProvider?.uid,
      username: configuredProvider?.username || configuredProvider?.uid,
      authorizationId: configuredProvider?.id,
    }
  })
})

const tableHeaders: TableHeader[] = [
  {
    key: 'application',
    label: __('Application'),
  },
  {
    key: 'username',
    label: __('Username'),
    truncate: true,
  },
]

const tableItems = computed<TableItem[]>(() =>
  providersLookup.value.map((provider, index) => ({
    id: `${index}-${provider.name}`,
    application: provider.label,
    ...provider,
  })),
)

const loading = ref(false)

const unlinkMutation = async (
  authId: string,
  authProvider: EnumAuthenticationProvider,
  uid: string,
) => {
  return new MutationHandler(
    useUserCurrentRemoveLinkedAccountMutation(() => ({
      update(cache) {
        if (user.value === null) return

        // Evict authorization cache to align in-memory cache
        const normalizedId = cache.identify({
          authId,
          __typename: 'Authorization',
        })
        cache.evict({ id: normalizedId })

        // Identify current user cache and update authorizations field to align in-memory cache
        cache.modify({
          id: cache.identify(user.value),
          fields: {
            authorizations(existingAuthorizations, { readField }) {
              return existingAuthorizations.filter(
                (auth: Authorization) => readField('id', auth) !== authId,
              )
            },
          },
        })

        cache.gc()
      },
    })),
  ).send({
    provider: authProvider,
    uid,
  })
}

const { waitForVariantConfirmation } = useConfirmation()

const unlinkAccount = async (providerTableItem: LinkedAccountTableItem) => {
  const confirmed = await waitForVariantConfirmation('delete')

  if (!confirmed) return

  try {
    loading.value = true
    const response = await unlinkMutation(
      providerTableItem.authorizationId,
      providerTableItem.name,
      providerTableItem.uid,
    )

    if (!response?.userCurrentRemoveLinkedAccount) return

    const { success } = response.userCurrentRemoveLinkedAccount

    if (success)
      notify({
        id: 'linked-account-removed',
        type: NotificationTypes.Success,
        message: __('The account link was successfully removed!'),
      })
  } finally {
    loading.value = false
  }
}

const tableActions = computed((): MenuItem[] => [
  {
    key: 'delete',
    icon: 'trash3',
    variant: 'danger',
    ariaLabel: (provider) =>
      i18n.t('Remove account link on %s', provider?.application),
    show: (provider) => !!provider?.username,
    onClick: (provider) => unlinkAccount(provider as LinkedAccountTableItem),
  },
  {
    key: 'setup',
    icon: 'plus-square-fill',
    variant: 'secondary',
    ariaLabel: (provider) =>
      i18n.t('Link account on %s', provider?.application),
    show: (provider) => !provider?.username,
  },
])
</script>

<template>
  <LayoutContent :breadcrumb-items="breadcrumbItems" width="narrow">
    <CommonSimpleTable
      :headers="tableHeaders"
      :items="tableItems"
      :actions="tableActions"
    >
      <template #actions="{ actions, item }">
        <div class="flex items-center justify-center">
          <template v-for="action in actions" :key="action.key">
            <CommonThirdPartyAuthenticationButton
              v-if="action.key === 'setup' && action.show?.(item)"
              button-class="flex"
              :button-icon="action.icon"
              :disabled="loading"
              button-size="medium"
              :button-label="(action?.ariaLabel as Function)(item)"
              :url="`${item?.url}?fingerprint=${fingerprint}`"
            />
            <CommonButton
              v-else-if="action.onClick && action.show?.(item)"
              :icon="action.icon"
              :disabled="loading"
              :class="{ '!bg-transparent': action.variant === 'danger' }"
              size="medium"
              :variant="action.variant"
              :aria-label="(action?.ariaLabel as Function)(item)"
              @click="action.onClick?.(item)"
            />
          </template>
        </div>
      </template>
    </CommonSimpleTable>
  </LayoutContent>
</template>
