<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import type { AvatarOrganization } from '#shared/components/CommonOrganizationAvatar/types.ts'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import { useOrganizationObjectAttributesStore } from '#shared/entities/organization/stores/objectAttributes.ts'
import type { Organization } from '#shared/graphql/types.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
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
    () => ({ organizationId: props.organizationAvatar.id }),
    () => ({ enabled: !!props.organizationAvatar.id, fetchPolicy: 'cache-and-network' }),
  ),
)

const organizationResult = organizationInfoForPopoverQuery.result()

const organization = computed(
  () => organizationResult.value?.organization as Partial<Organization> | null,
)

const loading = organizationInfoForPopoverQuery.loading()

const { debouncedLoading } = useDebouncedLoading({
  isLoading: loading,
})

const organizationMembers = computed(() => normalizeEdges(organization.value?.allMembers) || [])

const { viewScreenAttributes } = storeToRefs(useOrganizationObjectAttributesStore())

const router = useRouter()

const goToOrganizationProfile = () => {
  if (!organization.value) return

  router.push(`/organization/profile/${organization.value.internalId}`)
}
</script>

<template>
  <section ref="popover-section" data-type="popover" class="space-y-2 p-3">
    <OrganizationPopoverSkeleton v-if="debouncedLoading && !organization" />
    <template v-else-if="organization">
      <OrganizationInfo :organization="organization" no-link />

      <ObjectAttributes
        :class="{
          'border-b border-neutral-100 dark:border-gray-900 pb-2.5':
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
      >
        <template #trailing="{ totalCount, entities }">
          <CommonButton
            v-if="totalCount - entities.length"
            class="self-end"
            variant="secondary"
            size="small"
            @click="goToOrganizationProfile"
          >
            {{ $t('%s more', totalCount - entities.length) }}
          </CommonButton>
        </template>
      </CommonSimpleEntityList>
    </template>
  </section>
</template>
