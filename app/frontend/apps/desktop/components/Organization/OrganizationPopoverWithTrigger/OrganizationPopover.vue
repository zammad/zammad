<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import { useRouter } from 'vue-router'

import type { AvatarOrganization } from '#shared/components/CommonOrganizationAvatar/types.ts'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useOrganizationObjectAttributesStore } from '#shared/entities/organization/stores/objectAttributes.ts'
import type { Organization } from '#shared/graphql/types.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import OrganizationInfo from '#desktop/components/Organization/OrganizationInfo.vue'
import OrganizationPopoverSkeleton from '#desktop/components/Organization/OrganizationPopoverWithTrigger/skeleton/OrganizationPopoverSkeleton.vue'

import { useOrganizationInfoForPopoverQuery } from './graphql/queries/organizationInfoForPopover.api.ts'

interface Props {
  organizationAvatar: AvatarOrganization
}

const props = defineProps<Props>()

const organizationInfoForPopoverQuery = new QueryHandler(
  useOrganizationInfoForPopoverQuery(
    () => ({ organizationId: props.organizationAvatar.id, membersCount: 5 }),
    () => ({ enabled: !!props.organizationAvatar.id, fetchPolicy: 'cache-and-network' }),
  ),
)

const organizationResult = organizationInfoForPopoverQuery.result()

const organization = computed(
  () => organizationResult.value?.organization as Partial<Organization> | null,
)

const loading = organizationInfoForPopoverQuery.loadingWithoutCachedResult()

const organizationMembers = computed(() => normalizeEdges(organization.value?.allMembers) || [])

const viewScreenAttributes = toRef(useOrganizationObjectAttributesStore(), 'viewScreenAttributes')

const router = useRouter()

const goToOrganizationProfile = () => {
  if (!organization.value) return

  router.push(`/organizations/${organization.value.internalId}`)
}
</script>

<template>
  <section ref="popover-section" data-type="popover" class="space-y-2 p-3">
    <CommonLoader no-transition :loading="loading">
      <template #skeleton>
        <OrganizationPopoverSkeleton />
      </template>

      <div v-if="organization" class="space-y-2">
        <OrganizationInfo :organization="organization" no-link />

        <ObjectAttributes
          :class="{
            'border-b border-neutral-100 pb-2.5 dark:border-gray-900':
              organizationMembers?.totalCount,
          }"
          :object="organization"
          :attributes="viewScreenAttributes"
          :skip-attributes="['name', 'vip', 'active']"
        />

        <CommonSimpleEntityList
          id="organization-members-popover"
          :type="EntityType.User"
          :label="__('Members')"
          :entity="organizationMembers"
          no-collapse
          @load-more="goToOrganizationProfile"
        />
      </div>
    </CommonLoader>
  </section>
</template>
