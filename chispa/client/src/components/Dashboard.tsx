import { useEffect, useRef } from 'react'
import { motion, useReducedMotion } from 'framer-motion'
import type { AnalysisResult } from '../types/analysis'
import { VerdictCard } from './VerdictCard'
import { RiskRadarChart } from './RiskRadarChart'
import { MarketSnapshot } from './MarketSnapshot'
import { CompetitorCard } from './CompetitorCard'
import { FirstSteps } from './FirstSteps'

interface DashboardProps {
  result: AnalysisResult
}

export function Dashboard({ result }: DashboardProps) {
  const dashboardRef = useRef<HTMLDivElement>(null)
  const shouldReduceMotion = useReducedMotion()

  useEffect(() => {
    dashboardRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }, [])

  return (
    <motion.div
      ref={dashboardRef}
      initial={shouldReduceMotion ? { opacity: 0 } : { y: 40, opacity: 0 }}
      animate={shouldReduceMotion ? { opacity: 1 } : { y: 0, opacity: 1 }}
      transition={{ duration: shouldReduceMotion ? 0.15 : 0.5, ease: 'easeOut' }}
      className="w-full max-w-4xl mx-auto space-y-6 pb-16"
    >
      {/* Verdict — visually dominant, full width */}
      <VerdictCard verdict={result.verdict} verdictReason={result.verdictReason} />

      {/* Two-column: radar chart + market snapshot */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <RiskRadarChart risks={result.risks} />
        <MarketSnapshot
          marketSize={result.marketSize}
          marketGrowth={result.marketGrowth}
          marketTiming={result.marketTiming}
        />
      </div>

      {/* Competitors */}
      {result.competitors.length > 0 ? (
        <div className="space-y-4">
          <h3 className="text-sm font-medium text-gray-300 uppercase tracking-widest">
            Competidores
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {result.competitors.map((competitor, index) => (
              <CompetitorCard key={index} competitor={competitor} />
            ))}
          </div>
        </div>
      ) : (
        <div className="bg-surface border border-border rounded-xl p-6">
          <h3 className="text-sm font-medium text-gray-300 uppercase tracking-widest mb-2">
            Competidores
          </h3>
          <p className="text-gray-400 text-sm">
            No se encontraron competidores directos — eso puede ser una ventaja.
          </p>
        </div>
      )}

      {/* First steps — only for LAUNCH or VALIDATE */}
      <FirstSteps verdict={result.verdict} firstSteps={result.firstSteps} />
    </motion.div>
  )
}
