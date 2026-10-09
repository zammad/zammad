// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// IndexedDB, not Cache Storage: on iOS a page only sees Cache Storage as it
//   was when the page started, so it misses what the worker writes for a push
//   later on. Writes to IndexedDB it sees right away.

export interface ShownPushNotification {
  tag: string
  path: string
  shownAt: number
}

const DATABASE_NAME = 'zammad-push-notifications'
const STORE_NAME = 'shown'

export const isDatabaseAvailable = () => typeof indexedDB !== 'undefined'

const openDatabase = () =>
  new Promise<IDBDatabase>((resolve, reject) => {
    const request = indexedDB.open(DATABASE_NAME, 1)

    request.onupgradeneeded = () => request.result.createObjectStore(STORE_NAME, { keyPath: 'tag' })
    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error)
  })

const withStore = async <T>(
  mode: IDBTransactionMode,
  action: (store: IDBObjectStore) => IDBRequest<T> | void,
) => {
  const database = await openDatabase()

  try {
    return await new Promise<T | undefined>((resolve, reject) => {
      const transaction = database.transaction(STORE_NAME, mode)
      const request = action(transaction.objectStore(STORE_NAME))

      transaction.oncomplete = () => resolve(request?.result)
      transaction.onerror = () => reject(transaction.error)
    })
  } finally {
    database.close()
  }
}

export const readEntries = async () =>
  (await withStore<ShownPushNotification[]>('readonly', (store) => store.getAll())) ?? []

export const putEntry = (entry: ShownPushNotification) =>
  withStore('readwrite', (store) => {
    store.put(entry)
  })

export const deleteEntries = (tags: string[]) =>
  withStore('readwrite', (store) => {
    tags.forEach((tag) => store.delete(tag))
  })

export const deleteDatabase = () =>
  new Promise<void>((resolve, reject) => {
    const request = indexedDB.deleteDatabase(DATABASE_NAME)

    request.onsuccess = () => resolve()
    request.onerror = () => reject(request.error)
    // Another tab still has it open, it is removed once that one closes it.
    request.onblocked = () => resolve()
  })
