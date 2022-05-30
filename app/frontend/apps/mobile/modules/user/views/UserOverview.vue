<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'
import useAuthenticationStore from '@shared/stores/authentication'
import { useNotifications } from '@shared/components/CommonNotifications'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import type { MenuItem } from '@mobile/components/CommonSectionMenu'

const { clearAllNotifications } = useNotifications()
const authentication = useAuthenticationStore()
const router = useRouter()

const logoutMenu: MenuItem[] = [
  {
    type: 'link',
    onClick() {
      clearAllNotifications()
      authentication.logout().then(() => {
        router.push('/login')
      })
    },
    title: __('Logout'),
  },
]
</script>

<template>
  <CommonSectionMenu :items="logoutMenu" />
</template>
