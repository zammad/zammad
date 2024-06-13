<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useUserCurrentAccessTokenDeleteMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentAccessTokenDelete.api.ts'
import { useUserCurrentAccessTokenListQuery } from '#shared/entities/user/current/graphql/queries/userCurrentAcessTokenList.api.ts'
import type {
  Token,
  UserCurrentAccessTokenUpdatesSubscription,
  UserCurrentAccessTokenUpdatesSubscriptionVariables,
  UserCurrentAccessTokenListQuery,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSimpleTable from '#desktop/components/CommonSimpleTable/CommonSimpleTable.vue'
import type {
  TableHeader,
  TableItem,
} from '#desktop/components/CommonSimpleTable/types.ts'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'

import { useCheckTokenAccess } from '../composables/permission/useCheckTokenAccess.ts'
import { useBreadcrumb } from '../composables/useBreadcrumb.ts'
import { UserCurrentAccessTokenUpdatesDocument } from '../graphql/subscriptions/userCurrentAccessTokenUpdates.api.ts'

defineOptions({
  beforeRouteEnter() {
    const { canUseAccessToken } = useCheckTokenAccess()

    if (!canUseAccessToken.value) {
      // TODO: Redirect to error page using redirectToError or something similar.
      return '/error'
    }

    return true
  },
})

const session = useSessionStore()

const { breadcrumbItems } = useBreadcrumb(__('Token Access'))

const newAccessTokenFlyout = useFlyout({
  name: 'new-access-token',
  component: () =>
    import('../components/PersonalSettingNewAccessTokenFlyout.vue'),
})

const accessTokenListQuery = new QueryHandler(
  useUserCurrentAccessTokenListQuery(),
)

const accessTokenListQueryResult = accessTokenListQuery.result()
const accessTokenListLoading = accessTokenListQuery.loading()

accessTokenListQuery.subscribeToMore<
  UserCurrentAccessTokenUpdatesSubscriptionVariables,
  UserCurrentAccessTokenUpdatesSubscription
>({
  document: UserCurrentAccessTokenUpdatesDocument,
  variables: {
    userId: session.user?.id || '',
  },
  updateQuery: (prev, { subscriptionData }) => {
    if (!subscriptionData.data?.userCurrentAccessTokenUpdates.tokens) {
      return null as unknown as UserCurrentAccessTokenListQuery
    }

    return {
      userCurrentAccessTokenList:
        subscriptionData.data.userCurrentAccessTokenUpdates.tokens,
    }
  },
})

const tableHeaders: TableHeader[] = [
  {
    key: 'name',
    label: __('Name'),
    truncate: true,
  },
  {
    key: 'permissions',
    label: __('Permissions'),
    truncate: true,
  },
  {
    key: 'createdAt',
    label: __('Created'),
    type: 'timestamp',
  },
  {
    key: 'expiresAt',
    label: __('Expires'),
    type: 'timestamp',
  },
  {
    key: 'lastUsedAt',
    label: __('Last Used'),
    type: 'timestamp',
  },
]

const { notify } = useNotifications()

const { waitForVariantConfirmation } = useConfirmation()

const deleteDevice = (accessToken: Token) => {
  const accessTokenDeleteMutation = new MutationHandler(
    useUserCurrentAccessTokenDeleteMutation(() => ({
      variables: {
        tokenId: accessToken.id,
      },
      update(cache) {
        cache.evict({ id: cache.identify(accessToken) })
        cache.gc()
      },
    })),
    {
      errorNotificationMessage: __(
        'The personal access token could not be deleted.',
      ),
    },
  )

  accessTokenDeleteMutation.send().then(() => {
    notify({
      type: NotificationTypes.Success,
      message: __('Personal access token has been deleted.'),
    })
  })
}

const confirmDeleteDevice = async (accessToken: Token) => {
  const confirmed = await waitForVariantConfirmation('delete')

  if (confirmed) deleteDevice(accessToken)
}

const tableActions: MenuItem[] = [
  {
    key: 'delete',
    label: __('Delete this access token'),
    icon: 'trash3',
    variant: 'danger',
    onClick: (data) => {
      confirmDeleteDevice(data as Token)
    },
  },
]

const currentAccessTokens = computed<TableItem[]>(() => {
  return (
    accessTokenListQueryResult.value?.userCurrentAccessTokenList || []
  ).map((accessToken) => {
    return {
      ...accessToken,
      permissions: accessToken.preferences?.permission?.join(', ') || '',
    }
  })
})

const currentAccessTokenPresent = computed(
  () => currentAccessTokens.value.length > 0,
)

const helpText = computed(() => [
  i18n.t(
    'You can generate a personal access token for each application you use that needs access to the Zammad API.',
  ),
  i18n.t("Pick a name for the application, and we'll give you a unique token."),
])
</script>

<template>
  <LayoutContent
    :help-text="helpText"
    :show-inline-help="!currentAccessTokenPresent && !accessTokenListLoading"
    :breadcrumb-items="breadcrumbItems"
    width="narrow"
  >
    <template #headerRight>
      <div class="flex flex-row gap-2">
        <CommonButton
          prefix-icon="key"
          variant="primary"
          size="medium"
          @click="newAccessTokenFlyout.open()"
        >
          {{ $t('New Personal Access Token') }}
        </CommonButton>
      </div>
    </template>

    <CommonLoader :loading="accessTokenListLoading">
      <div class="mb-4">
        <CommonSimpleTable
          :headers="tableHeaders"
          :items="currentAccessTokens"
          :actions="tableActions"
          :aria-label="$t('Personal Access Tokens')"
          class="min-w-150"
        >
          <template #item-suffix-name="{ item }">
            <CommonBadge
              v-if="item.current"
              size="medium"
              variant="info"
              class="ltr:ml-2 rtl:mr-2"
              >{{ $t('This device') }}
            </CommonBadge>
          </template>
        </CommonSimpleTable>
      </div>
    </CommonLoader>
  </LayoutContent>
</template>
