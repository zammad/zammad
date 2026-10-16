// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticle, TicketById } from '#shared/entities/ticket/types.ts'
import type {
  TicketArticleAction,
  TicketArticlePerformOptions,
} from '#shared/entities/ticket-article/action/plugins/types.ts'
import { createDeferred } from '#shared/utils/helpers.ts'
import log from '#shared/utils/log.ts'

import { usePendingArticleAction } from '../usePendingArticleAction.ts'

const ticket = {} as TicketById
const article = { id: 'gid://zammad/Ticket::Article/1' } as TicketArticle
const options = {} as TicketArticlePerformOptions

const createAction = (perform: TicketArticleAction['perform'], name = 'email-reply') =>
  ({ name, perform }) as TicketArticleAction

describe('usePendingArticleAction', () => {
  it('marks the action and its article as pending until the perform promise settles', async () => {
    const { isPending, isActionPending, isArticlePending, performAction } =
      usePendingArticleAction()
    const deferred = createDeferred<void>()

    const run = performAction(
      createAction(() => deferred.promise),
      ticket,
      article,
      options,
    )

    expect(isPending.value).toBe(true)
    expect(isActionPending('email-reply', article.id)).toBe(true)
    expect(isActionPending('email-forward', article.id)).toBe(false)
    expect(isArticlePending(article.id)).toBe(true)
    expect(isArticlePending('gid://zammad/Ticket::Article/2')).toBe(false)

    deferred.resolve()
    await run

    expect(isPending.value).toBe(false)
    expect(isActionPending('email-reply', article.id)).toBe(false)
    expect(isArticlePending(article.id)).toBe(false)
  })

  it('is not pending after a synchronous action', async () => {
    const { isPending, performAction } = usePendingArticleAction()
    const perform = vi.fn()

    await performAction(createAction(perform), ticket, article, options)

    expect(perform).toHaveBeenCalledOnce()
    expect(isPending.value).toBe(false)
  })

  it('ignores further actions while one is pending', async () => {
    const { performAction } = usePendingArticleAction()
    const deferred = createDeferred<void>()
    const firstPerform = vi.fn(() => deferred.promise)
    const secondPerform = vi.fn()

    const run = performAction(createAction(firstPerform), ticket, article, options)
    await performAction(createAction(secondPerform, 'email-forward'), ticket, article, options)

    expect(secondPerform).not.toHaveBeenCalled()

    deferred.resolve()
    await run
    await performAction(createAction(secondPerform, 'email-forward'), ticket, article, options)

    expect(secondPerform).toHaveBeenCalledOnce()
  })

  it('releases the pending state and logs when the action fails', async () => {
    const errorSpy = vi.spyOn(log, 'error').mockImplementation(() => {})
    const { isPending, performAction } = usePendingArticleAction()
    const deferred = createDeferred<void>()
    const error = new Error('nope')

    const run = performAction(
      createAction(() => deferred.promise),
      ticket,
      article,
      options,
    )

    deferred.reject(error)

    await expect(run).resolves.toBeUndefined()
    expect(isPending.value).toBe(false)
    expect(errorSpy).toHaveBeenCalledWith('[Article Action] "email-reply" failed', error)
  })
})
