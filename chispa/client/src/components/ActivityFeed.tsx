import { useEffect, useRef } from 'react'
import { motion, useReducedMotion } from 'framer-motion'
import type { SSEMessage } from '../types/analysis'

type StepMessage = Extract<SSEMessage, { type: 'step' }>

interface ActivityFeedProps {
  steps: StepMessage[]
}

export function ActivityFeed({ steps }: ActivityFeedProps) {
  const bottomRef = useRef<HTMLDivElement>(null)
  const shouldReduceMotion = useReducedMotion()

  // Auto-scroll to bottom when new steps arrive
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [steps.length])

  if (steps.length === 0) {
    return (
      <div className="w-full max-w-2xl mx-auto">
        <div className="bg-surface border border-border rounded-lg p-6">
          <div className="flex items-center gap-3" role="status" aria-live="polite">
            <div className="w-2 h-2 bg-primary rounded-full animate-pulse" aria-hidden="true" />
            <span className="text-gray-400 text-sm">Iniciando análisis...</span>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="w-full max-w-2xl mx-auto">
      <div className="bg-surface border border-border rounded-lg overflow-hidden">
        <div className="px-4 py-3 border-b border-border">
          <h3 className="text-sm font-medium text-gray-300">Actividad en tiempo real</h3>
        </div>
        <div
          className="max-h-64 overflow-y-auto p-4 space-y-3"
          aria-live="polite"
          aria-label="Pasos del análisis en curso"
        >
          {steps.map((step, index) => (
            <motion.div
              key={index}
              initial={shouldReduceMotion ? { opacity: 0 } : { opacity: 0, x: -8 }}
              animate={shouldReduceMotion ? { opacity: 1 } : { opacity: 1, x: 0 }}
              transition={{
                duration: shouldReduceMotion ? 0.1 : 0.3,
                delay: 0,
                ease: 'easeOut',
              }}
              className="flex items-start gap-3"
            >
              <div className="mt-1.5 w-1.5 h-1.5 bg-primary rounded-full flex-shrink-0" aria-hidden="true" />
              <div className="flex-1 min-w-0">
                <span className="text-sm text-gray-200">{step.text}</span>
                {step.source && (
                  <span className="ml-2 inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-primary/20 text-primary-light border border-primary/30">
                    {step.source}
                  </span>
                )}
              </div>
            </motion.div>
          ))}
          <div ref={bottomRef} />
        </div>
      </div>
    </div>
  )
}
