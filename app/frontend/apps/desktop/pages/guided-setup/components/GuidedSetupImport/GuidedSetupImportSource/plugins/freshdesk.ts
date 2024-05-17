// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumSystemImportSource } from '#shared/graphql/types.ts'

import GuidedSetupImportSourceFreshdesk from '../GuidedSetupImportSourceFreshdesk.vue'

import type { GuidedSetupImportSourcePlugin } from './index.ts'

export default <GuidedSetupImportSourcePlugin>{
  source: EnumSystemImportSource.Freshdesk,
  label: __('Freshdesk'),
  beta: true,
  component: GuidedSetupImportSourceFreshdesk,
  importEntities: {
    Groups: __('Groups'),
    Organizations: __('Organizations'),
    Users: __('Users'),
    Tickets: __('Tickets'),
  },
  documentationURL:
    'https://docs.zammad.org/en/latest/migration/freshdesk.html',
}
