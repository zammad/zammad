// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumSystemImportSource } from '#shared/graphql/types.ts'

import GuidedSetupImportSourceZendesk from '../GuidedSetupImportSourceZendesk.vue'

import type { GuidedSetupImportSourcePlugin } from './index.ts'

export default <GuidedSetupImportSourcePlugin>{
  source: EnumSystemImportSource.Zendesk,
  label: __('Zendesk'),
  beta: true,
  component: GuidedSetupImportSourceZendesk,
  importEntities: {
    Groups: __('Groups'),
    Organizations: __('Organizations'),
    Users: __('Users'),
    Tickets: __('Tickets'),
  },
  documentationURL: 'https://docs.zammad.org/en/latest/migration/zendesk.html',
}
