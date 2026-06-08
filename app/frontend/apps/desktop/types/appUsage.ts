// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ComputedGetter } from 'vue'

export interface TimeTrackerOptions {
  /**
   * @tickTime Interval in milliseconds
   */
  tickTime?: number
  enabled?: ComputedGetter<boolean | undefined>
}

export type MilestoneKey = '1h' | '5h' | '20h'

export type MilestoneRecords = Record<MilestoneKey, { reached: boolean; triggerHistory: boolean }>

export type MilestonesHistoryRecords = Record<MilestoneKey, boolean>
