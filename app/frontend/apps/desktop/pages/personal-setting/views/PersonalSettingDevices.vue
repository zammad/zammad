<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import useFingerprint from '#shared/composables/useFingerprint.ts'
import type {
  UserCurrentDevicesUpdatesSubscription,
  UserCurrentDevicesUpdatesSubscriptionVariables,
  UserCurrentDeviceListQuery,
  UserDevice,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSimpleTable from '#desktop/components/CommonSimpleTable/CommonSimpleTable.vue'
import type {
  TableHeader,
  TableItem,
} from '#desktop/components/CommonSimpleTable/types.ts'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'
import { useUserCurrentDeviceDeleteMutation } from '../graphql/mutations/userCurrentDeviceDelete.api.ts'
import { useUserCurrentDeviceListQuery } from '../graphql/queries/userCurrentDeviceList.api.ts'
import { UserCurrentDevicesUpdatesDocument } from '../graphql/subscriptions/userCurrentDevicesUpdates.api.ts'

const session = useSessionStore()

const { breadcrumbItems } = useBreadcrumb(__('Devices'))

const { notify } = useNotifications()

const { fingerprint } = useFingerprint()

const deviceListQuery = new QueryHandler(useUserCurrentDeviceListQuery())
const deviceListQueryResult = deviceListQuery.result()
const deviceListQueryLoading = deviceListQuery.loading()

deviceListQuery.subscribeToMore<
  UserCurrentDevicesUpdatesSubscriptionVariables,
  UserCurrentDevicesUpdatesSubscription
>({
  document: UserCurrentDevicesUpdatesDocument,
  variables: {
    userId: session.user?.id || '',
  },
  updateQuery: (prev, { subscriptionData }) => {
    if (!subscriptionData.data?.userCurrentDevicesUpdates.devices) {
      return null as unknown as UserCurrentDeviceListQuery
    }

    return {
      userCurrentDeviceList:
        subscriptionData.data.userCurrentDevicesUpdates.devices,
    }
  },
})

const { waitForVariantConfirmation } = useConfirmation()

const deleteDevice = (device: UserDevice) => {
  const deviceDeleteMutation = new MutationHandler(
    useUserCurrentDeviceDeleteMutation(() => ({
      variables: {
        deviceId: device.id,
      },
      update(cache) {
        cache.evict({ id: cache.identify(device) })
        cache.gc()
      },
    })),
    {
      errorNotificationMessage: __('The device could not be deleted.'),
    },
  )

  deviceDeleteMutation.send().then(() => {
    notify({
      type: NotificationTypes.Success,
      message: __('Device has been revoked.'),
    })
  })
}

const confirmDeleteDevice = async (device: UserDevice) => {
  const confirmed = await waitForVariantConfirmation('delete')

  if (confirmed) deleteDevice(device)
}

const tableHeaders: TableHeader[] = [
  {
    key: 'name',
    label: __('Name'),
    truncate: true,
  },
  {
    key: 'location',
    label: __('Location'),
    truncate: true,
  },
  {
    key: 'updatedAt',
    label: __('Most recent activity'),
    type: 'timestamp',
  },
]

const tableActions: MenuItem[] = [
  {
    key: 'delete',
    label: __('Delete this device'),
    icon: 'trash3',
    variant: 'danger',
    show: (data) => !data?.current,
    onClick: (data) => {
      confirmDeleteDevice(data as UserDevice)
    },
  },
]

const currentDevices = computed<TableItem[]>(() => {
  return (deviceListQueryResult.value?.userCurrentDeviceList || []).map(
    (device) => {
      return {
        ...device,
        current: device.fingerprint && device.fingerprint === fingerprint.value,
      }
    },
  )
})

const helpText = computed(() =>
  i18n.t(
    'All computers and browsers from which you logged in to Zammad appear here.',
  ),
)
</script>

<template>
  <LayoutContent
    :breadcrumb-items="breadcrumbItems"
    :help-text="helpText"
    width="narrow"
    provide-default
  >
    <CommonLoader :loading="deviceListQueryLoading">
      <div class="mb-4">
        <CommonSimpleTable
          :headers="tableHeaders"
          :items="currentDevices"
          :actions="tableActions"
          class="min-w-150"
          :aria-label="helpText"
        >
          <template #item-suffix-name="{ item }">
            <CommonBadge
              v-if="item.current"
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
