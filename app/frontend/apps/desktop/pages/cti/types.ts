// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { CtiLogsQuery, CtiSidebarQuery } from '#shared/graphql/types.ts'

export type CallerLogEntry = CtiLogsQuery['ctiLogs']['edges'][number]['node']

export type CallerLogMatch = CallerLogEntry['fromMatches'][number]

export type RingingCall = CtiSidebarQuery['ctiSidebar']['ringingCalls'][number]
