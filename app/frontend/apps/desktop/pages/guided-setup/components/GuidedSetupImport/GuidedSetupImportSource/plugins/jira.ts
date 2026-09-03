// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumSystemImportSource } from '#shared/graphql/types.ts'

import GuidedSetupImportSourceJira from '../GuidedSetupImportSourceJira.vue'

import type { GuidedSetupImportSourcePlugin } from './index.ts'

export default <GuidedSetupImportSourcePlugin>{
  source: EnumSystemImportSource.Jira,
  label: __('Jira'),
  beta: true,
  component: GuidedSetupImportSourceJira,
  importEntities: {
    Users: __('Users'),
    Tickets: __('Tickets'),
  },
  documentationURL: 'https://docs.zammad.org/en/latest/migration/jira.html',
}
