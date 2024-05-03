<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { storeToRefs } from 'pinia'

import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import useFingerprint from '#shared/composables/useFingerprint.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type {
  UserCurrentDevicesUpdatesSubscription,
  UserCurrentDevicesUpdatesSubscriptionVariables,
  UserCurrentDeviceListQuery,
  UserDevice,
} from '#shared/graphql/types.ts'

import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSimpleTable from '#desktop/components/CommonSimpleTable/CommonSimpleTable.vue'
import type { MenuItem } from '#desktop/components/CommonPopover/types.ts'
import type {
  TableHeader,
  TableItem,
} from '#desktop/components/CommonSimpleTable/types.ts'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'
import { useUserCurrentDeviceListQuery } from '../graphql/queries/userCurrentDeviceList.api.ts'
import { useUserCurrentDeviceDeleteMutation } from '../graphql/mutations/userCurrentDeviceDelete.api.ts'
import { UserCurrentDevicesUpdatesDocument } from '../graphql/subscriptions/userCurrentDevicesUpdates.api.ts'

const { user } = storeToRefs(useSessionStore())

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
    userId: user.value?.id || '',
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
  },
  {
    key: 'location',
    label: __('Location'),
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
</script>

<template>
  <LayoutContent provide-default :breadcrumb-items="breadcrumbItems">
    <div class="max-w-150 mb-4">
      <CommonLoader :loading="deviceListQueryLoading">
        <CommonLabel class="!mt-0.5 mb-1 !block">{{
          $t(
            'All computers and browsers that have access to your Zammad appear here.',
          )
        }}</CommonLabel>

        <CommonSimpleTable
          :headers="tableHeaders"
          :items="currentDevices"
          :actions="tableActions"
          class="w-150"
        >
          <template #item-suffix-name="{ item }">
            <CommonBadge
              v-if="item.current"
              size="medium"
              variant="info"
              class="ltr:ml-2 rtl:mr-2"
              >{{ $t('This device') }}</CommonBadge
            >
          </template>
        </CommonSimpleTable>
      </CommonLoader>
    </div>
  </LayoutContent>
</template>
