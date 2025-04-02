<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, watch, onActivated } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import type {
  UserCurrentOverviewListQuery,
  UserCurrentOverviewOrderingUpdatesSubscription,
  UserCurrentOverviewOrderingUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { UserCurrentOverviewOrderingUpdatesDocument } from '#desktop/entities/ticket/graphql/subscriptions/userCurrentOverviewOrderingUpdates.api.ts'

import PersonalSettingOverviewOrder, {
  type OverviewItem,
} from '../components/PersonalSettingOverviewOrder.vue'
import { useBreadcrumb } from '../composables/useBreadcrumb.ts'
import { useUserCurrentOverviewResetOrderMutation } from '../graphql/mutations/userCurrentOverviewResetOrder.api.ts'
import { useUserCurrentOverviewUpdateOrderMutation } from '../graphql/mutations/userCurrentOverviewUpdateOrder.api.ts'
import { useUserCurrentOverviewListQuery } from '../graphql/queries/userCurrentOverviewList.api.ts'

const { breadcrumbItems } = useBreadcrumb(__('Overviews'))

const overviewList = ref<OverviewItem[]>([])

const overviewListQuery = new QueryHandler(
  useUserCurrentOverviewListQuery({ ignoreUserConditions: true }),
)

const overviewListQueryLoading = overviewListQuery.loading()

onActivated(() => overviewListQuery.refetch())

overviewListQuery.subscribeToMore<
  UserCurrentOverviewOrderingUpdatesSubscriptionVariables,
  UserCurrentOverviewOrderingUpdatesSubscription
>({
  document: UserCurrentOverviewOrderingUpdatesDocument,
  variables: { ignoreUserConditions: true },
  updateQuery: (_, { subscriptionData }) => {
    if (!subscriptionData.data?.userCurrentOverviewOrderingUpdates.overviews) {
      return null as unknown as UserCurrentOverviewListQuery
    }

    return {
      userCurrentTicketOverviews:
        subscriptionData.data.userCurrentOverviewOrderingUpdates.overviews,
    }
  },
})

watch(overviewListQuery.result(), (newValue) => {
  overviewList.value = newValue?.userCurrentTicketOverviews || []
})

const { notify } = useNotifications()

const updateOverviewList = (newValue: OverviewItem[]) => {
  // Update the local order immediately, in order to avoid laggy UX.
  overviewList.value = newValue

  const overviewUpdateOrderMutation = new MutationHandler(
    useUserCurrentOverviewUpdateOrderMutation(),
    {
      errorNotificationMessage: __(
        'Updating the order of your ticket overviews failed.',
      ),
    },
  )

  overviewUpdateOrderMutation
    .send({
      overviewIds: newValue.map((overview) => overview.id),
    })
    .then(() => {
      notify({
        id: 'overview-ordering-success',
        type: NotificationTypes.Success,
        message: __('The order of your ticket overviews was updated.'),
      })
    })
}

const { waitForVariantConfirmation } = useConfirmation()

const resetOverviewOrder = () => {
  const userCurrentOverviewResetOrderMutation = new MutationHandler(
    useUserCurrentOverviewResetOrderMutation(),
    {
      errorNotificationMessage: __(
        'Resetting the order of your ticket overviews failed.',
      ),
    },
  )

  userCurrentOverviewResetOrderMutation.send().then((data) => {
    if (data?.userCurrentOverviewResetOrder?.success) {
      notify({
        id: 'overview-ordering-delete-success',
        type: NotificationTypes.Success,
        message: __('The order of your ticket overviews was reset.'),
      })

      if (data.userCurrentOverviewResetOrder.overviews) {
        overviewList.value = data.userCurrentOverviewResetOrder.overviews
      }
    }
  })
}

const confirmResetOverviewOrder = async () => {
  const confirmed = await waitForVariantConfirmation('confirm')

  if (confirmed) resetOverviewOrder()
}
</script>

<template>
  <LayoutContent :breadcrumb-items="breadcrumbItems" width="narrow">
    <CommonLoader class="mt-5 mb-3" :loading="overviewListQueryLoading">
      <div class="mb-4">
        <CommonLabel
          id="label-ticket-overview-order"
          class="!mt-0.5 mb-1 !block"
          >{{ $t('Order of ticket overviews') }}
        </CommonLabel>

        <PersonalSettingOverviewOrder
          :model-value="overviewList"
          aria-labelledby="label-ticket-overview-order"
          @update:model-value="updateOverviewList"
        />

        <div class="flex flex-col items-end">
          <CommonButton
            :aria-label="$t('Reset Overview Order')"
            class="mt-4"
            variant="danger"
            size="medium"
            @click.stop="confirmResetOverviewOrder"
          >
            {{ $t('Reset Overview Order') }}
          </CommonButton>
        </div>
      </div>
    </CommonLoader>
  </LayoutContent>
</template>
