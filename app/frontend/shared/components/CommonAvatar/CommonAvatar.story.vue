<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonAvatar from './CommonAvatar.vue'

const transparentImage = `data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAIAQMAAAD+wSzIAAAABlBMVEX///+/v7+jQ3Y5AAAADklEQVQI12P4AIX8EAgALgAD/aNpbtEAAAAASUVORK5CYII`
</script>

<template>
  <Story>
    <Variant title="With Image">
      <CommonAvatar :image="transparentImage" initials="JD" />
    </Variant>
    <Variant title="VIP">
      <CommonAvatar :image="transparentImage" vip initials="JD" />
    </Variant>
    <Variant title="Without Image">
      <CommonAvatar initials="JD" class="bg-yellow" />
    </Variant>
    <Variant title="With Icon">
      <CommonAvatar icon="mobile-facebook" class="bg-blue" />
    </Variant>
    <Variant title="Large">
      <CommonAvatar initials="JD" vip class="bg-red" size="large" />
    </Variant>
  </Story>
</template>
