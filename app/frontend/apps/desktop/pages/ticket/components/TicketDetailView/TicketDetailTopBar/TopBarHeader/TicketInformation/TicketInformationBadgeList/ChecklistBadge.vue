<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <CommonBadge tag="div" variant="info" class="flex items-center gap-1">
    <CommonIcon name="checklist" size="xs" />
    <slot name="label">
      <CommonLabel size="small" class="text-current uppercase">
        {{ $t('tracked in') }}
      </CommonLabel>
    </slot>
    <slot />
  </CommonBadge>
</template>
