export interface Competitor {
  name: string
  description: string
  funding?: string
  founded?: string
  website?: string
}

export interface Risk {
  title: string
  severity: 'high' | 'medium' | 'low'
  mitigation: string
}

export interface AnalysisResult {
  competitors: Competitor[]
  marketSize: string
  marketGrowth: string
  marketTiming: 'too_early' | 'right_time' | 'too_late'
  risks: Risk[]
  verdict: 'LAUNCH' | 'VALIDATE' | 'PIVOT' | 'AVOID'
  verdictReason: string
  firstSteps: string[]
  searchedAt: string
}

export type SSEMessage =
  | { type: 'step'; text: string; source?: string }
  | { type: 'result'; data: AnalysisResult }
  | { type: 'error'; message: string }
  | { type: 'ping' }
