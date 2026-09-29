// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

type LockRequest = {
  callback: () => Promise<unknown> | unknown
  resolve: () => void
  reject: (reason: Error) => void
}

// Stands in for `navigator.locks`, which jsdom does not have: an exclusive
//   queue per lock name with the steal and signal semantics of the Web Locks
//   API. Every request goes through the same manager, so a request made from
//   the spec plays the part of another tab of the same origin.
class LockManagerMock {
  private held = new Map<string, LockRequest>()

  private queues = new Map<string, LockRequest[]>()

  request(
    name: string,
    options: { steal?: boolean; signal?: AbortSignal },
    callback: LockRequest['callback'],
  ) {
    return new Promise<void>((resolve, reject) => {
      const request: LockRequest = { callback, resolve, reject }
      const queue = this.queues.get(name) ?? []

      this.queues.set(name, queue)

      options.signal?.addEventListener('abort', () => {
        if (!queue.includes(request)) return

        queue.splice(queue.indexOf(request), 1)
        reject(new DOMException('The request was aborted.', 'AbortError'))
      })

      if (options.steal) {
        this.held.get(name)?.reject(new DOMException('The lock was stolen.', 'AbortError'))
        this.held.delete(name)
        queue.unshift(request)
      } else {
        queue.push(request)
      }

      this.grant(name)
    })
  }

  private grant(name: string) {
    if (this.held.has(name)) return

    const request = this.queues.get(name)?.shift()

    if (!request) return

    this.held.set(name, request)

    Promise.resolve(request.callback()).then(() => {
      // A stolen lock has been given to someone else in the meantime.
      if (this.held.get(name) !== request) return

      this.held.delete(name)
      request.resolve()
      this.grant(name)
    })
  }
}

export const mockWebLocks = () => {
  Object.defineProperty(navigator, 'locks', { value: new LockManagerMock(), configurable: true })
}

export const unmockWebLocks = () => {
  // @ts-expect-error restoring the browser without the API
  delete navigator.locks
}

// Holds the lock the way another tab would; `lost` records the takeover by a third one.
export const holdLockFromAnotherTab = (name: string, steal = false) => {
  let release!: () => void

  const held = new Promise<void>((resolve) => {
    release = resolve
  })

  const lost = vi.fn()

  navigator.locks.request(name, { steal }, () => held).catch(lost)

  return { release, lost }
}
