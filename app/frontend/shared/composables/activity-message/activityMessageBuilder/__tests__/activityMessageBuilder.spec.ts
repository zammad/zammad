// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { activityMessageBuilder } from '../index.ts'

describe('activity message builder are available', () => {
  it('should return all search plugins', () => {
    const builderList = activityMessageBuilder

    const models = Object.keys(builderList)

    expect(models).toContain('Ticket')
    expect(models).toContain('User')
    expect(models).toContain('Organization')
    expect(models).toContain('Group')
  })
})
