<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonUserAvatar from './CommonUserAvatar.vue'
</script>

<template>
  <Story>
    <Variant title="System User">
      <CommonUserAvatar
        :entity="{
          id: '1',
        }"
      />
    </Variant>
    <Variant title="Without Icon">
      <CommonUserAvatar
        :entity="{
          id: '2',
          firstname: 'John',
          lastname: 'Doe',
        }"
      />
    </Variant>
    <Variant title="Facebook User">
      <CommonUserAvatar
        :entity="{
          id: '2',
          source: 'facebook',
        }"
      />
    </Variant>
    <Variant title="VIP">
      <CommonUserAvatar
        :entity="{
          id: '2',
          vip: true,
          email: 'jd@email.com',
        }"
        :personal="false"
      />
    </Variant>
    <Variant title="Inactive">
      <CommonUserAvatar
        :entity="{
          id: '2',
          active: false,
          firstname: 'John',
          lastname: 'Doe',
        }"
      />
    </Variant>
    <Variant title="On Vacation">
      <CommonUserAvatar
        :entity="{
          id: '2',
          outOfOffice: true,
          firstname: 'John',
          lastname: 'Doe',
        }"
      />
    </Variant>
  </Story>
</template>
