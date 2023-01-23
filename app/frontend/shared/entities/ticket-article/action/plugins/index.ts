// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticle, TicketById } from '@shared/entities/ticket/types'
import { getTicketView } from '@shared/entities/ticket/utils/getTicketView'
import { useApplicationStore } from '@shared/stores/application'
import type { AppName } from '@shared/types/app'
import type {
  TicketTypeAddOptions,
  TicketActionAddOptions,
  TicketArticleActionPlugin,
  TicketViewPolicyMap,
  AppSpecificTicketArticleType,
} from './types'

const pluginsModules = import.meta.glob<TicketArticleActionPlugin>(
  ['./*.ts', '!./initialize.ts', '!./types.ts', '!./__tests__/**/*.ts'],
  {
    eager: true,
    import: 'default',
  },
)

export const articleActionPlugins = Object.values(pluginsModules).sort(
  (p1, p2) => p1.order - p2.order,
)

const createFilter = (options: TicketTypeAddOptions, app: AppName) => {
  return (object: { view: TicketViewPolicyMap; apps: AppName[] }) => {
    if (!object.apps.includes(app)) return false
    const view = object.view[options.view.ticketView]
    if (!view || !view.length) return false
    if (view.includes('read')) return true
    if (options.view.isTicketEditable && view.includes('change')) return true
    return false
  }
}

export const createArticleActions = (
  ticket: TicketById,
  article: TicketArticle,
  app: AppName,
  _options: Pick<TicketActionAddOptions, 'onDispose' | 'recalculate'>,
) => {
  const application = useApplicationStore()
  const options = {
    ..._options,
    view: getTicketView(ticket),
    config: application.config,
  }
  const filterByView = createFilter(options, app)
  return articleActionPlugins
    .map((p) => p.addActions?.(ticket, article, options) || [])
    .flat()
    .filter(filterByView)
}

export const createArticleTypes = (
  ticket: TicketById,
  app: AppName,
): AppSpecificTicketArticleType[] => {
  const application = useApplicationStore()
  const options: TicketTypeAddOptions = {
    view: getTicketView(ticket),
    config: application.config,
  }
  const filterByView = createFilter(options, app)
  return (
    articleActionPlugins
      .map((p) => p.addTypes?.(ticket, options) || [])
      .flat()
      .filter(filterByView)
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      .map(({ apps, ...type }) => ({
        ...type,
        icon: type.icon[app],
      }))
  )
}
