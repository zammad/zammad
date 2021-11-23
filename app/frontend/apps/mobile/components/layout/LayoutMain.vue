<!-- Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div class="flex flex-col h-screen overflow-hidden">
    <main class="flex-1 overflow-y-scroll">
      <router-view v-slot="{ Component }">
        <transition>
          <component v-bind:is="Component" />
        </transition>
      </router-view>
    </main>
    <footer class="w-full bg-darker text-center border-t p-4">
      Bottom-Navigation
    </footer>
  </div>
</template>
