<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { i18n } from '#shared/i18n/index.ts'
import openExternalLink from '#shared/utils/openExternalLink.ts'

import CommonButtonGroup from '#desktop/components/CommonButtonGroup/CommonButtonGroup.vue'
import type { CommonButtonItem } from '#desktop/components/CommonButtonGroup/types.ts'

const downloadPluginAndContinue = (downloadLink: string) => {
  openExternalLink(downloadLink)
}

const otrsPlugins: CommonButtonItem[] = [
  {
    label: i18n.t('Migration Plugin for %s', 'OTRS 6'),
    variant: 'primary',
    size: 'medium',
    icon: 'download',
    onActionClick: () =>
      downloadPluginAndContinue(
        'https://ftp.zammad.com/otrs-migrator-plugins/Znuny4OTRS-ZammadMigrator-6.0.7.opm',
      ),
  },
  {
    label: i18n.t('Migration Plugin for %s', 'OTRS 5'),
    variant: 'primary',
    size: 'medium',
    icon: 'download',
    onActionClick: () =>
      downloadPluginAndContinue(
        'https://ftp.zammad.com/otrs-migrator-plugins/Znuny4OTRS-ZammadMigrator-5.0.4.opm',
      ),
  },
  {
    label: i18n.t('Migration Plugin for %s', 'OTRS 4'),
    variant: 'primary',
    size: 'medium',
    icon: 'download',
    onActionClick: () =>
      downloadPluginAndContinue(
        'https://ftp.zammad.com/otrs-migrator-plugins/Znuny4OTRS-ZammadMigrator-4.1.12.opm',
      ),
  },
  {
    label: i18n.t('Migration Plugin for %s', 'OTRS 3.3-3.1'),
    variant: 'primary',
    size: 'medium',
    icon: 'download',
    onActionClick: () =>
      downloadPluginAndContinue(
        'https://ftp.zammad.com/otrs-migrator-plugins/Znuny4OTRS-ZammadMigrator-3.0.33.opm',
      ),
  },
]
</script>

<template>
  <CommonButtonGroup :items="otrsPlugins" />
</template>
