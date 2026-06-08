// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef } from 'vue'

import type { TicketStatsMonthly } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'

import type { BarChartOptions } from '#desktop/components/CommonCharts/CommonBarChart/types.ts'
import { useChartStyles } from '#desktop/components/CommonCharts/useChartStyles.ts'

export const useTicketStatsChart = (
  statsData: ComputedRef<Array<TicketStatsMonthly> | undefined>,
) => {
  const { colorMap, fontFamily, isDarkMode } = useChartStyles()

  const chartData = computed(() => {
    const stats = statsData.value || []

    // Reverse to get chronological order (Dec 2024 -> Nov 2025)
    const reversedStats = [...stats].reverse()

    return {
      months: reversedStats.map((stat) => i18n.t(stat.monthLabel).toUpperCase()),
      created: reversedStats.map((stat) => stat.ticketsCreated),
      closed: reversedStats.map((stat) => stat.ticketsClosed),
    }
  })

  const barColors = computed(() => ({
    created: isDarkMode.value ? colorMap['gray-200'] : colorMap['stone-400'],
    closed: colorMap['green-400'],
  }))

  const axisColors = computed(() => ({
    line: isDarkMode.value ? colorMap['neutral-800'] : colorMap['neutral-700'], // baseline
    splitLine: isDarkMode.value ? colorMap['neutral-800'] : colorMap['neutral-700'], // lines above baseline
    text: isDarkMode.value ? colorMap['neutral-500'] : colorMap['stone-200'],
    title: isDarkMode.value ? colorMap['white'] : colorMap['black'],
    legend: isDarkMode.value ? colorMap['neutral-400'] : colorMap['gray-100'],
  }))

  const option = computed<BarChartOptions>(() => ({
    aria: {
      enabled: true,
      label: {
        description: i18n.t(
          'Bar chart showing ticket statistics. Created and closed tickets over the last 12 months.',
        ),
      },
    },
    title: {
      text: i18n.t('Ticket frequency'),
      left: 0,
      textStyle: {
        fontFamily,
        fontWeight: 'normal',
        fontSize: '0.875rem',
        color: axisColors.value.title,
      },
    },
    tooltip: {
      trigger: 'axis',
      backgroundColor: isDarkMode.value ? colorMap['gray-500'] : colorMap['neutral-50'],
      borderColor: isDarkMode.value ? colorMap['gray-900'] : colorMap['neutral-100'],
      borderRadius: 12,
      shadowBlur: 0,
      shadowColor: 'transparent',
      borderWidth: 1,
      textStyle: {
        color: isDarkMode.value ? colorMap['neutral-400'] : colorMap['gray-100'],
        fontFamily,
      },
      axisPointer: {
        type: 'shadow',
        shadowStyle: {
          color: isDarkMode.value ? 'rgba(0, 0, 0, 0.2)' : 'rgba(0, 0, 0, 0.1)',
        },
      },
      formatter: (params: unknown) => {
        if (!Array.isArray(params)) return ''
        const month = params[0]?.axisValue || ''
        const items = params
          .map((param: unknown) => {
            const p = param as { color: string; seriesName: string; value: number }
            // same of the legend swatch
            const marker = `<span style="display:inline-block;margin-right:8px;border-radius:2px;width:20px;height:8px;background-color:${p.color};"></span>`
            return `${marker}${p.seriesName}: ${p.value}`
          })
          .join('<br/>')
        return `${month}<br/>${items}`
      },
    },
    legend: {
      data: [i18n.t('Created'), i18n.t('Closed')],
      left: 0,
      itemWidth: 20,
      itemHeight: 8,
      itemGap: 40,
      textStyle: {
        fontFamily,
        color: axisColors.value.legend,
      },
    },
    grid: {
      left: '0%',
      right: '0%',
      top: '20%',
    },
    xAxis: {
      type: 'category',
      data: chartData.value.months,
      axisLine: {
        lineStyle: { color: axisColors.value.line },
      },
      axisTick: {
        lineStyle: { color: axisColors.value.line },
      },
      axisLabel: {
        fontFamily,
        color: axisColors.value.text,
      },
    },
    yAxis: {
      type: 'value',
      minInterval: 1, // Ensures only integer intervals
      axisLine: {
        lineStyle: { color: axisColors.value.line },
      },
      axisLabel: {
        fontFamily,
        color: axisColors.value.text,
      },
      splitLine: {
        lineStyle: {
          color: axisColors.value.splitLine,
          width: 0.5,
        },
      },
    },
    series: [
      {
        name: i18n.t('Created'),
        type: 'bar',
        data: chartData.value.created,
        barWidth: 4,
        barGap: 1,
        barCategoryGap: 1,
        itemStyle: {
          color: barColors.value.created,
          borderRadius: 8,
        },
        emphasis: {
          itemStyle: {
            color: barColors.value.created,
          },
        },
      },
      {
        name: i18n.t('Closed'),
        type: 'bar',
        data: chartData.value.closed,
        barWidth: 8,
        // Inherits barGap and barCategoryGap behavior from first series
        itemStyle: {
          color: barColors.value.closed,
          borderRadius: 8,
        },
        emphasis: {
          itemStyle: {
            color: barColors.value.closed,
          },
        },
      },
    ],
    backgroundColor: 'transparent',
  }))

  return {
    option,
  }
}
