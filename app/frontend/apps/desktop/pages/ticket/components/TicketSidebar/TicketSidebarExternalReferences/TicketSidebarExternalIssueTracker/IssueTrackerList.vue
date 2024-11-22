<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { cloneDeep } from 'lodash-es'
import { computed, toRef, watch } from 'vue'

import type { FormRef } from '#shared/components/Form/types.ts'
import {
  EnumTicketExternalReferencesIssueTrackerType,
  type TicketExternalReferencesIssueTrackerItem,
  type TicketExternalReferencesIssueTrackerItemListQuery,
} from '#shared/graphql/types.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import IssueTrackerItem from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarExternalIssueTracker/IssueTrackerList/IssueTrackerItem.vue'
import { useTicketExternalIssueTracker } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarExternalIssueTracker/useTicketExternalIssueTracker.ts'
import type { ExternalReferencesFormValues } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/types.ts'
import { useTicketExternalReferencesIssueTrackerItemAddMutation } from '#desktop/pages/ticket/graphql/mutations/ticketExternalReferencesIssueTrackerItemAdd.api.ts'
import { useTicketExternalReferencesIssueTrackerItemRemoveMutation } from '#desktop/pages/ticket/graphql/mutations/ticketExternalReferencesIssueTrackerItemRemove.api.ts'
import { TicketExternalReferencesIssueTrackerItemListDocument } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIssueTrackerList.api.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

interface Props {
  screenType: TicketSidebarScreenType
  isTicketEditable: boolean
  trackerType: EnumTicketExternalReferencesIssueTrackerType
  flyoutConfig: {
    name: string
    icon: string
    label: string
    inputPlaceholder: string
  }
  issueLinks: string[]
  form?: FormRef
  ticketId?: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  error: [string | null]
}>()

const { isLoadingIssues, issueList, skipNextLinkUpdate, error } =
  useTicketExternalIssueTracker(
    props.screenType,
    props.trackerType,
    toRef(props, 'issueLinks'),
    props.ticketId,
  )

watch(error, () => {
  emit('error', error.value)
})

const unlinkMutation = new MutationHandler(
  useTicketExternalReferencesIssueTrackerItemRemoveMutation(),
  {
    errorShowNotification: false,
  },
)

const removeIssueLinkListCacheUpdate = (
  issue: TicketExternalReferencesIssueTrackerItem,
) => {
  const { cache } = getApolloClient()

  const queryOptions = {
    query: TicketExternalReferencesIssueTrackerItemListDocument,
    variables: {
      issueTrackerType: props.trackerType,
      ticketId: props.ticketId,
      issueTrackerLinks: props.ticketId ? undefined : props.issueLinks,
    },
  }

  const existingIssueTrackerItems =
    cache.readQuery<TicketExternalReferencesIssueTrackerItemListQuery>(
      queryOptions,
    )

  if (!existingIssueTrackerItems) return

  const oldIssueTrackerItems = cloneDeep(existingIssueTrackerItems)

  cache.writeQuery({
    ...queryOptions,
    data: {
      ticketExternalReferencesIssueTrackerItemList:
        existingIssueTrackerItems.ticketExternalReferencesIssueTrackerItemList.filter(
          (issueItem) => issueItem.issueId !== issue.issueId,
        ),
    },
  })

  return () => {
    cache.writeQuery({
      ...queryOptions,
      data: oldIssueTrackerItems,
    })
  }
}

const unlinkIssue = async (issue: TicketExternalReferencesIssueTrackerItem) => {
  const revertCacheUpdate = removeIssueLinkListCacheUpdate(issue)

  if (props.screenType === TicketSidebarScreenType.TicketCreate) {
    const externalReferences = props.form?.findNodeByName('externalReferences')

    const { values } = props.form as { values: ExternalReferencesFormValues }

    if (
      !externalReferences ||
      !externalReferences.value ||
      !values.externalReferences ||
      !values.externalReferences[props.trackerType]
    )
      return

    return externalReferences?.input(
      {
        ...values.externalReferences,
        [props.trackerType]: values?.externalReferences[
          props.trackerType
        ]?.filter((link) => link !== issue.url),
      },
      false,
    )
  }

  return unlinkMutation
    .send({
      issueTrackerLink: issue.url,
      issueTrackerType: props.trackerType,
      ticketId: props.ticketId as string,
    })
    .catch(() => revertCacheUpdate)
}

const linkIssueMutation = new MutationHandler(
  useTicketExternalReferencesIssueTrackerItemAddMutation({
    update: (cache, { data }) => {
      if (!data) return

      const { ticketExternalReferencesIssueTrackerItemAdd } = data
      if (!ticketExternalReferencesIssueTrackerItemAdd?.issueTrackerItem) return

      const queryOptions = {
        query: TicketExternalReferencesIssueTrackerItemListDocument,
        variables: {
          issueTrackerType: props.trackerType,
          ticketId: props.ticketId,
          issueTrackerLinks: props.ticketId ? undefined : props.issueLinks,
        },
      }

      let existingIssueTrackerItems =
        cache.readQuery<TicketExternalReferencesIssueTrackerItemListQuery>(
          queryOptions,
        )

      const newIdPresent =
        existingIssueTrackerItems?.ticketExternalReferencesIssueTrackerItemList?.find(
          (issueItem) => {
            return (
              issueItem.issueId ===
              ticketExternalReferencesIssueTrackerItemAdd?.issueTrackerItem
                ?.issueId
            )
          },
        )
      if (newIdPresent) return

      existingIssueTrackerItems = {
        ...existingIssueTrackerItems,
        ticketExternalReferencesIssueTrackerItemList: [
          ...(existingIssueTrackerItems?.ticketExternalReferencesIssueTrackerItemList ||
            []),
          ticketExternalReferencesIssueTrackerItemAdd?.issueTrackerItem,
        ],
      }

      if (!props.ticketId) {
        queryOptions.variables.issueTrackerLinks = [
          ...(props.issueLinks || []),
          ticketExternalReferencesIssueTrackerItemAdd.issueTrackerItem.url,
        ]
      }

      cache.writeQuery({
        ...queryOptions,
        data: {
          ...existingIssueTrackerItems,
        },
      })
    },
  }),
  {
    errorShowNotification: false,
  },
)

const linkIssue = async (link: string) => {
  skipNextLinkUpdate.value = true

  return linkIssueMutation
    .send({
      issueTrackerLink: link,
      issueTrackerType: props.trackerType,
      ticketId: props.ticketId,
    })
    .then((result) => {
      // For ticket create we need to remember the url inside the hidden form field.
      if (props.screenType === TicketSidebarScreenType.TicketCreate) {
        const issueUrl =
          result?.ticketExternalReferencesIssueTrackerItemAdd?.issueTrackerItem
            ?.url

        if (!issueUrl) return

        const externalReferences =
          props.form?.findNodeByName('externalReferences')

        if (!externalReferences) return

        let existingIssueLinks = cloneDeep(
          externalReferences.value,
        ) as ExternalReferencesFormValues['externalReferences']

        existingIssueLinks ||= {}
        existingIssueLinks[props.trackerType] = [
          ...(existingIssueLinks[props.trackerType] || []),
          issueUrl,
        ]

        externalReferences?.input(existingIssueLinks, false)
      }
    })
    .finally(() => {
      skipNextLinkUpdate.value = false
    })
}

const linkIssueFlyout = useFlyout({
  component: () => import('./IssueTrackerLinkFlyout.vue'),
  name: props.flyoutConfig.name,
})

const openFlyout = () => {
  linkIssueFlyout.open({
    ...props.flyoutConfig,
    issueLinks: props.issueLinks,
    onSubmit: (link: string) => linkIssue(link),
  })
}

const showEmptyState = computed(() => {
  if (props.ticketId) {
    return (
      issueList.value !== undefined &&
      issueList.value.length === 0 &&
      props.isTicketEditable
    )
  }

  return props.form?.formInitialSettled && !props.issueLinks?.length
})

defineExpose({
  openFlyout,
})
</script>

<template>
  <CommonLoader :loading="isLoadingIssues" :error="error">
    <div class="space-y-6">
      <CommonButton
        v-if="showEmptyState"
        size="medium"
        variant="primary"
        class="block ltr:w-full rtl:w-full"
        @click="openFlyout"
      >
        {{ $t('Link Issue') }}
      </CommonButton>

      <div v-else role="list" class="space-y-5">
        <IssueTrackerItem
          v-for="issue in issueList"
          :key="issue.issueId"
          role="listitem"
          :is-editable="isTicketEditable"
          :issue="issue"
          @unlink="unlinkIssue"
        />
      </div>
    </div>
  </CommonLoader>
</template>
