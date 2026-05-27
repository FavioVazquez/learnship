import { useReducedMotion } from 'framer-motion'
import {
  RadarChart,
  Radar,
  PolarAngleAxis,
  PolarGrid,
  ResponsiveContainer,
} from 'recharts'
import type { Risk } from '../types/analysis'

interface RiskRadarChartProps {
  risks: Risk[]
}

const AXES = ['Mercado', 'Competencia', 'Técnico', 'Regulatorio', 'Timing', 'Capital'] as const

const SEVERITY_VALUE: Record<Risk['severity'] | 'missing', number> = {
  high: 90,
  medium: 60,
  low: 30,
  missing: 20,
}

function buildChartData(risks: Risk[]) {
  return AXES.map((axis) => {
    // Prefer the explicit category field — reliable when Claude follows the prompt
    const categoryMatch = risks.find((r) => r.category === axis)
    if (categoryMatch) {
      return { axis, value: SEVERITY_VALUE[categoryMatch.severity] }
    }
    // Fallback: case-insensitive partial match on title for older/incomplete responses
    const partialMatch = risks.find((r) =>
      r.title.toLowerCase().includes(axis.toLowerCase()) ||
      axis.toLowerCase().includes(r.title.toLowerCase())
    )
    return {
      axis,
      value: partialMatch ? SEVERITY_VALUE[partialMatch.severity] : SEVERITY_VALUE.missing,
    }
  })
}

export function RiskRadarChart({ risks }: RiskRadarChartProps) {
  const data = buildChartData(risks)
  const prefersReducedMotion = useReducedMotion()

  return (
    <div className="bg-surface border border-border rounded-xl p-6">
      <h3 className="text-sm font-medium text-gray-300 mb-4">Análisis de Riesgos</h3>
      <ResponsiveContainer width="100%" height={280}>
        <RadarChart data={data}>
          <PolarGrid stroke="#1f1f2e" />
          <PolarAngleAxis
            dataKey="axis"
            tick={{ fill: '#9ca3af', fontSize: 12 }}
          />
          <Radar
            dataKey="value"
            stroke="#7c3aed"
            fill="#7c3aed"
            fillOpacity={0.3}
            isAnimationActive={!prefersReducedMotion}
          />
        </RadarChart>
      </ResponsiveContainer>
    </div>
  )
}
