import { motion, useReducedMotion } from 'framer-motion'
import type { AnalysisResult } from '../types/analysis'

interface FirstStepsProps {
  verdict: AnalysisResult['verdict']
  firstSteps: string[]
}

export function FirstSteps({ verdict, firstSteps }: FirstStepsProps) {
  // Only render for actionable verdicts — PIVOT and AVOID don't get next steps
  if (verdict !== 'LAUNCH' && verdict !== 'VALIDATE') return null
  if (firstSteps.length === 0) return null

  const shouldReduceMotion = useReducedMotion()

  return (
    <div className="bg-surface border border-border rounded-xl p-6">
      <h3 className="text-sm font-medium text-gray-300 uppercase tracking-widest mb-5">
        Primeros pasos
      </h3>
      <ol className="space-y-4">
        {firstSteps.slice(0, 5).map((step, index) => (
          <motion.li
            key={index}
            initial={shouldReduceMotion ? { opacity: 0 } : { opacity: 0, x: -12 }}
            animate={shouldReduceMotion ? { opacity: 1 } : { opacity: 1, x: 0 }}
            transition={{
              duration: shouldReduceMotion ? 0.1 : 0.35,
              delay: shouldReduceMotion ? 0 : index * 0.07,
              ease: 'easeOut',
            }}
            className="flex items-start gap-4"
          >
            <span
              className="flex-shrink-0 w-7 h-7 rounded-full bg-primary/20 border border-primary/40 flex items-center justify-center text-xs font-bold text-primary-light"
            >
              {index + 1}
            </span>
            <p className="text-gray-200 text-sm leading-relaxed pt-0.5">{step}</p>
          </motion.li>
        ))}
      </ol>
    </div>
  )
}
