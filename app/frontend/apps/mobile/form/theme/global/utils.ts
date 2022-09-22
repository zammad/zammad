// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

export type Classes = Record<string, string>

export const clean = (str: string) => str.replace(/\s{2,}/g, ' ').trim()
