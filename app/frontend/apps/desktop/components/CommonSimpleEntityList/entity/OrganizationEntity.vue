<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { AvatarOrganization } from '#shared/components/CommonOrganizationAvatar'
import CommonOrganizationAvatar from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import type { Organization } from '#shared/graphql/types.ts'

interface Props {
  entity: Organization
}
defineProps<Props>()
</script>

<template>
  <CommonLink
    :link="`/organizations/${entity.internalId}`"
    class="flex gap-2 hover:no-underline"
  >
    <!--            :TODO add popover with user details-->
    <CommonOrganizationAvatar
      :entity="entity as AvatarOrganization"
      size="small"
    />
    <CommonLabel class="text-blue-800 hover:underline"
      >{{ entity.name }}
    </CommonLabel>
  </CommonLink>
</template>
