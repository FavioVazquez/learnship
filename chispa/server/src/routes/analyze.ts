import { Router, Request, Response } from 'express'
import type { SSEMessage } from '../types/analysis.js'
import { analyzeIdea } from '../agent/analyzer.js'

let activeAnalyses = 0
const MAX_CONCURRENT = 3

function sendSSE(res: Response, msg: SSEMessage): void {
  res.write(`data: ${JSON.stringify(msg)}\n\n`)
}

const router = Router()

router.post('/api/analyze', async (req: Request, res: Response): Promise<void> => {
  const body = req.body as { idea?: unknown; country?: unknown }
  const idea = body.idea
  if (typeof idea !== 'string' || idea.length < 20 || idea.length > 500) {
    res.status(400).json({ error: 'El campo "idea" debe tener entre 20 y 500 caracteres.' })
    return
  }
  const country = typeof body.country === 'string' && body.country.length <= 100 ? body.country : undefined

  if (activeAnalyses >= MAX_CONCURRENT) {
    res.status(429).json({ error: 'Demasiados análisis en curso. Intenta en unos segundos.' })
    return
  }
  activeAnalyses++

  res.setHeader('Content-Type', 'text/event-stream')
  res.setHeader('Cache-Control', 'no-cache')
  res.setHeader('Connection', 'keep-alive')
  res.setHeader('X-Accel-Buffering', 'no')
  res.flushHeaders()

  const abortController = new AbortController()
  req.on('close', () => abortController.abort())

  try {
    for await (const msg of analyzeIdea(idea, country, abortController.signal)) {
      if (abortController.signal.aborted) break
      sendSSE(res, msg)
    }
  } catch (err: unknown) {
    if (!abortController.signal.aborted) {
      sendSSE(res, {
        type: 'error',
        message: 'Error interno del servidor. Intenta de nuevo.',
      })
    }
  } finally {
    activeAnalyses--
    res.end()
  }
})

export default router
