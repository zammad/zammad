<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import { useRouter } from 'vue-router'

import type { AvatarUser } from '#shared/components/CommonUserAvatar/types.ts'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useUserObjectAttributesStore } from '#shared/entities/user/stores/objectAttributes.ts'
import type { User } from '#shared/graphql/types.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import UserInfo from '#desktop/components/User/UserInfo.vue'
import UserPopoverSkeleton from '#desktop/components/User/UserPopoverWithTrigger/skeleton/UserPopoverSkeleton.vue'

import { useUserInfoForPopoverQuery } from './graphql/queries/userInfoForPopover.api.ts'

interface Props {
  userAvatar: AvatarUser
  noProfileLink?: boolean
}

const props = defineProps<Props>()

const userInfoForPopoverQuery = new QueryHandler(
  useUserInfoForPopoverQuery(
    () => ({ userId: props.userAvatar.id, secondaryOrganizationsCount: 5 }),
    () => ({ enabled: !!props.userAvatar.id, fetchPolicy: 'cache-and-network' }),
  ),
)

const userResult = userInfoForPopoverQuery.result()

const user = computed(() => userResult.value?.user as Partial<User> | null)

const loading = userInfoForPopoverQuery.loadingWithoutCachedResult()

const secondaryOrganizations = computed(() => normalizeEdges(user.value?.secondaryOrganizations))

const viewScreenAttributes = toRef(useUserObjectAttributesStore(), 'viewScreenAttributes')

const router = useRouter()

const goToUserProfile = () => {
  if (!user.value) return

  router.push(`/users/${user.value.internalId}`)
}
</script>

<template>
  <section ref="popover-section" data-type="popover" class="space-y-2 p-3">
    <UserPopoverSkeleton :loading="loading">
      <template v-if="user">
        <UserInfo :user="user" :no-link="noProfileLink" />

        <ObjectAttributes
          :class="{
            'border-b border-neutral-100 pb-2.5 dark:border-gray-900':
              secondaryOrganizations?.totalCount,
          }"
          :object="user!"
          :attributes="viewScreenAttributes"
          :skip-attributes="['firstname', 'lastname', 'organization_id', 'organization_ids']"
        />

        <CommonSimpleEntityList
          v-if="secondaryOrganizations.totalCount"
          id="customer-secondary-organizations-popover"
          no-collapse
          :type="EntityType.Organization"
          :label="__('Secondary organizations')"
          :entity="secondaryOrganizations"
          @load-more="goToUserProfile"
        />
      </template>
    </UserPopoverSkeleton>
  </section>
</template>
