// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ChannelModule } from '#desktop/pages/ticket/components/TicketDetailView/article-type/types.ts'

const articleTypeModules = import.meta.glob<ChannelModule>('./plugins/*.ts', {
  eager: true,
  import: 'default',
})

export const modules = Object.entries(articleTypeModules).map(([, module]) => {
  return module
})

export const lookupArticlePlugin = (pluginName?: string) =>
  modules.find((module) => module?.name === pluginName)
