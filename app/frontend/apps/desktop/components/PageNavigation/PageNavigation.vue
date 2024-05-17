<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'

import { sortedFirstLevelRoutes } from '#desktop/components/PageNavigation/firstLevelRoutes.ts'

import CommonButton from '../CommonButton/CommonButton.vue'

interface Props {
  iconOnly?: boolean
}

//*
// IMPORTANT: This is just a temporary implementations please replace and adapt it later
// *//
defineProps<Props>()

const router = useRouter()
</script>

<template>
  <div class="py-2 pt-14">
    <CommonLabel
      v-if="!iconOnly"
      class="mb-2 px-2 text-neutral-500"
      size="small"
    >
      {{ $t('Navigation') }}
    </CommonLabel>
    <nav>
      <ul>
        <li
          v-for="route in sortedFirstLevelRoutes"
          :key="route.path"
          class="flex justify-center"
        >
          <CommonButton
            v-if="iconOnly"
            class="text-neutral-400 hover:outline-blue-900"
            :class="{
              '!bg-blue-800 !text-white':
                router.currentRoute.value.path === route.path,
            }"
            size="medium"
            variant="neutral"
            :icon="route.meta.icon"
            @click="router.push(route.path)"
          />
          <CommonLink
            v-else
            class="flex grow gap-2 rounded-md px-2 py-3 text-neutral-400 hover:bg-blue-900 hover:text-white hover:no-underline"
            :link="route.path"
            exact-active-class="!bg-blue-800 w-full !text-white"
            internal
          >
            <CommonLabel
              class="gap-2 text-current"
              :prefix-icon="route.meta.icon"
            >
              {{ $t(route.meta.title) }}
            </CommonLabel>
          </CommonLink>
        </li>
      </ul>
    </nav>
  </div>
</template>
