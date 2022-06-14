<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'
import { storeToRefs } from 'pinia'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import type { MenuItem } from '@mobile/components/CommonSectionMenu'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import useSessionStore from '@shared/stores/session'
import CommonSectionMenuLink from '@mobile/components/CommonSectionMenu/CommonSectionMenuLink.vue'

const router = useRouter()

const logout = () => {
  router.push('/logout')
}

const menu: MenuItem[] = [
  {
    type: 'link',
    icon: { name: 'bell', size: 'base' },
    iconBg: 'bg-blue',
    title: __('Ticket notifications'),
  },
  {
    type: 'link',
    icon: { name: 'form', size: 'small' },
    iconBg: 'bg-orange',
    title: __('Language'),
  },
]

const { user } = storeToRefs(useSessionStore())
</script>

<template>
  <div class="px-4">
    <div v-if="user" class="flex flex-col items-center justify-center py-6">
      <div>
        <CommonUserAvatar :entity="user" size="xl" personal />
      </div>
      <div class="mt-2 text-xl font-bold">
        {{ user.firstname }} {{ user.lastname }}
      </div>
      <!-- TODO email -->
    </div>

    <!-- TODO maybe instead of a different page we can use a Dialog? -->
    <CommonSectionMenu>
      <CommonSectionMenuLink
        :icon="{ name: 'user', size: 'base' }"
        icon-bg="bg-pink"
        link="/account/avatar"
      >
        {{ $t('Avatar') }}
      </CommonSectionMenuLink>
    </CommonSectionMenu>

    <CommonSectionMenu :items="menu" />

    <CommonSectionMenu>
      <CommonSectionMenuLink
        :icon="{ name: 'info', size: 'base' }"
        icon-bg="bg-gray"
        information="v 1.1"
      >
        {{ $t('About') }}
      </CommonSectionMenuLink>
    </CommonSectionMenu>

    <div class="mb-4">
      <FormKit
        wrapper-class="mt-4 text-base flex grow justify-center items-center"
        input-class="py-2 px-4 w-full h-14 text-red formkit-variant-primary:bg-gray-500 rounded-xl select-none"
        type="submit"
        name="signout"
        @click="logout"
      >
        {{ $t('Sign out') }}
      </FormKit>
    </div>
  </div>
</template>
