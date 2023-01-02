// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export type Classes = Record<string, string>

export const clean = (str: string) => str.replace(/\s{2,}/g, ' ').trim()
