import { Router, Request, Response } from 'express'
import analyzeRouter from './analyze.js'

const router = Router()

router.get('/api/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  })
})

router.use(analyzeRouter)

export default router
