<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

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
import CommonEmptyMessage from '#desktop/components/CommonEmptyMessage/CommonEmptyMessage.vue'
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

const overviewListQuery = new QueryHandler(
  useUserCurrentOverviewListQuery({ ignoreUserConditions: true }),
)

const queryResult = overviewListQuery.result()

const overviewList = ref<OverviewItem[]>(queryResult.value?.userCurrentTicketOverviews || [])

const overviewListQueryLoading = overviewListQuery.loadingWithoutCachedResult()

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

watch(queryResult, (newValue) => {
  overviewList.value = newValue?.userCurrentTicketOverviews || []
})

const { notify } = useNotifications()

const updateOverviewList = (newValue: OverviewItem[]) => {
  // Update the local order immediately, in order to avoid laggy UX.
  overviewList.value = newValue

  const overviewUpdateOrderMutation = new MutationHandler(
    useUserCurrentOverviewUpdateOrderMutation(),
    {
      errorNotificationMessage: __('Updating the order of your ticket overviews failed.'),
    },
  )

  return overviewUpdateOrderMutation.send({
    overviewIds: newValue.map((overview) => overview.id),
  })
}

const { waitForVariantConfirmation } = useConfirmation()

const resetOverviewOrder = () => {
  const userCurrentOverviewResetOrderMutation = new MutationHandler(
    useUserCurrentOverviewResetOrderMutation(),
    {
      errorNotificationMessage: __('Resetting the order of your ticket overviews failed.'),
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
    <CommonLoader no-transition class="mt-5 mb-3" :loading="overviewListQueryLoading">
      <div v-if="overviewList.length" class="mb-4">
        <CommonLabel id="label-ticket-overview-order" class="mt-0.5! mb-1 block!"
          >{{ $t('Order of ticket overviews') }}
        </CommonLabel>

        <PersonalSettingOverviewOrder
          :model-value="overviewList"
          aria-labelledby="label-ticket-overview-order"
          @update:model-value="updateOverviewList"
        />

        <div class="flex flex-col items-end">
          <CommonButton
            class="mt-4"
            variant="danger"
            size="medium"
            @click.stop="confirmResetOverviewOrder"
          >
            {{ $t('Reset overview order') }}
          </CommonButton>
        </div>
      </div>
      <CommonEmptyMessage
        v-else
        class="text-center"
        :title="$t('No overviews')"
        :text="
          $t(
            'Currently, no overviews are assigned to your roles. Please contact your administrator.',
          )
        "
        icon="exclamation-triangle"
      />
    </CommonLoader>
  </LayoutContent>
</template>
