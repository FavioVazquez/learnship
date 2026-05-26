import React from 'react'
import { motion, useReducedMotion } from 'framer-motion'
import type { AnalysisResult } from '../types/analysis'

interface VerdictCardProps {
  verdict: AnalysisResult['verdict']
  verdictReason: string
}

const VERDICT_CONFIG: Record<AnalysisResult['verdict'], { label: string; color: string; bg: string }> = {
  LAUNCH:   { label: 'LANZA',  color: '#22c55e', bg: 'rgba(34,197,94,0.1)' },
  VALIDATE: { label: 'VALIDA', color: '#f59e0b', bg: 'rgba(245,158,11,0.1)' },
  PIVOT:    { label: 'PIVOTA', color: '#f97316', bg: 'rgba(249,115,22,0.1)' },
  AVOID:    { label: 'EVITA',  color: '#ef4444', bg: 'rgba(239,68,68,0.1)' },
}

export function VerdictCard({ verdict, verdictReason }: VerdictCardProps) {
  const config = VERDICT_CONFIG[verdict]
  const shouldReduceMotion = useReducedMotion()

  return (
    <div style={{ transformPerspective: 1000 } as React.CSSProperties} className="w-full">
      <motion.div
        initial={shouldReduceMotion ? { opacity: 0 } : { rotateX: 90, opacity: 0 }}
        animate={shouldReduceMotion ? { opacity: 1 } : { rotateX: 0, opacity: 1 }}
        transition={{ duration: shouldReduceMotion ? 0.15 : 0.5, ease: 'easeOut' }}
        className="bg-surface border border-border rounded-xl p-6"
        style={{ backgroundColor: config.bg, borderColor: config.color + '40' }}
      >
        <p className="text-xs font-medium uppercase tracking-widest mb-2" style={{ color: config.color }}>
          Veredicto
        </p>
        <h2
          className="text-5xl font-black mb-4 tracking-tight"
          style={{ color: config.color }}
        >
          {config.label}
        </h2>
        <p className="text-gray-300 text-sm leading-relaxed">{verdictReason}</p>
      </motion.div>
    </div>
  )
}
