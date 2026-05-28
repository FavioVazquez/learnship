import type { AnalysisResult } from '../types/analysis'

interface MarketSnapshotProps {
  marketSize: string
  marketGrowth: string
  marketTiming: AnalysisResult['marketTiming']
}

const TIMING_CONFIG: Record<AnalysisResult['marketTiming'], { label: string; color: string; bg: string }> = {
  too_early:  { label: 'Demasiado temprano', color: '#f59e0b', bg: 'rgba(245,158,11,0.1)' },
  right_time: { label: 'Momento perfecto',   color: '#22c55e', bg: 'rgba(34,197,94,0.1)' },
  too_late:   { label: 'Demasiado tarde',    color: '#ef4444', bg: 'rgba(239,68,68,0.1)' },
}

export function MarketSnapshot({ marketSize, marketGrowth, marketTiming }: MarketSnapshotProps) {
  const timing = TIMING_CONFIG[marketTiming] ?? {
    label: marketTiming,
    color: '#9ca3af',
    bg: 'rgba(156,163,175,0.1)',
  }

  return (
    <div className="bg-surface border border-border rounded-xl p-6 flex flex-col gap-5">
      <h3 className="text-sm font-medium text-gray-300">Panorama de Mercado</h3>

      <div className="flex flex-col gap-4">
        {/* Market size */}
        <div>
          <p className="text-xs text-gray-500 uppercase tracking-wider mb-1">Tamaño de mercado</p>
          <p className="text-white font-semibold text-xl leading-snug">{marketSize}</p>
        </div>

        {/* Market growth */}
        <div>
          <p className="text-xs text-gray-500 uppercase tracking-wider mb-1">Crecimiento</p>
          <p className="text-white font-semibold text-xl leading-snug">{marketGrowth}</p>
        </div>

        {/* Timing badge */}
        <div>
          <p className="text-xs text-gray-500 uppercase tracking-wider mb-2">Timing</p>
          <span
            className="inline-flex items-center px-3 py-1.5 rounded-full text-xs font-semibold"
            style={{ color: timing.color, backgroundColor: timing.bg, border: `1px solid ${timing.color}40` }}
          >
            {timing.label}
          </span>
        </div>
      </div>
    </div>
  )
}
