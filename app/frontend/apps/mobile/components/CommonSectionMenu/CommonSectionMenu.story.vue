<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSectionMenu from './CommonSectionMenu.vue'
import CommonSectionMenuLink from './CommonSectionMenuLink.vue'

const alert = window.alert?.bind(window)
</script>

<template>
  <Story>
    <Variant title="Default">
      <CommonSectionMenu
        :items="[
          {
            type: 'link',
            link: '/',
            icon: { name: 'mobile-all-tickets', size: 'base' },
            iconBg: 'bg-pink',
            label: 'Home',
          },
          {
            type: 'link',
            label: 'Action',
            onClick() {
              alert('click')
            },
          },
        ]"
      />
    </Variant>
    <Variant title="Action on click">
      <CommonSectionMenu
        header-label="Header"
        action-label="Click Me"
        :items="[
          {
            type: 'link',
            link: '/',
            icon: { name: 'mobile-all-tickets', size: 'base' },
            iconBg: 'bg-pink',
            label: 'Home',
          },
        ]"
        @action-click="alert('action clicked')"
      />
    </Variant>
    <Variant title="Slots">
      <CommonSectionMenu header-label="Header">
        <CommonSectionMenuLink label="Home" link="/" />
        <CommonSectionMenuLink
          label="Tickets"
          information="2"
          link="/tickets"
        />
      </CommonSectionMenu>
    </Variant>
  </Story>
</template>
