<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import type { AvatarUser } from '#shared/components/CommonUserAvatar/types.ts'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import { useUserObjectAttributesStore } from '#shared/entities/user/stores/objectAttributes.ts'
import type { User } from '#shared/graphql/types.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import UserInfo from '#desktop/components/User/UserInfo.vue'
import UserPopoverSkeleton from '#desktop/components/User/UserPopoverWithTrigger/skeleton/UserPopoverSkeleton.vue'

import { useUserInfoForPopoverQuery } from './graphql/queries/userInfoForPopover.api.ts'

interface Props {
  userAvatar: AvatarUser
}

const props = defineProps<Props>()

const userInfoForPopoverQuery = new QueryHandler(
  useUserInfoForPopoverQuery(
    () => ({ userId: props.userAvatar.id }),
    () => ({ enabled: !!props.userAvatar.id, fetchPolicy: 'cache-and-network' }),
  ),
)

const userResult = userInfoForPopoverQuery.result()

const user = computed(() => userResult.value?.user as Partial<User> | null)

const loading = userInfoForPopoverQuery.loading()

const { debouncedLoading } = useDebouncedLoading({
  isLoading: loading,
})

const secondaryOrganizations = computed(() => normalizeEdges(user.value?.secondaryOrganizations))

const { viewScreenAttributes } = storeToRefs(useUserObjectAttributesStore())

const router = useRouter()

const goToUserProfile = () => {
  if (!user.value) return

  router.push(`/user/profile/${user.value.internalId}`)
}
</script>

<template>
  <section ref="popover-section" data-type="popover" class="space-y-2 p-3">
    <UserPopoverSkeleton v-if="debouncedLoading && !user" />
    <template v-else-if="user">
      <UserInfo :user="user" no-link />

      <ObjectAttributes
        :class="{
          'border-b border-neutral-100 dark:border-gray-900 pb-2.5':
            secondaryOrganizations?.totalCount,
        }"
        :object="user!"
        :attributes="viewScreenAttributes"
        :skip-attributes="['firstname', 'lastname', 'organization_id']"
      />

      <CommonSimpleEntityList
        v-if="secondaryOrganizations.totalCount"
        id="customer-secondary-organizations-popover"
        no-collapse
        :type="EntityType.Organization"
        :label="__('Secondary organizations')"
        :entity="secondaryOrganizations"
      >
        <template #trailing="{ totalCount, entities }">
          <CommonButton
            v-if="totalCount - entities.length"
            class="self-end"
            variant="secondary"
            size="small"
            @click="goToUserProfile"
          >
            {{ $t('%s more', totalCount - entities.length) }}
          </CommonButton>
        </template>
      </CommonSimpleEntityList>
    </template>
  </section>
</template>
