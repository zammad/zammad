// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

// eslint-disable-next-line import/prefer-default-export
export const mergeArray = <T extends unknown[]>(a: T, b: T) => {
  return [...new Set([...a, ...b])]
}
