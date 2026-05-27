import 'dotenv/config'
import express from 'express'
import cors from 'cors'
import path from 'path'
import { fileURLToPath } from 'url'
import router from './routes/index.js'

if (!process.env.ANTHROPIC_API_KEY) {
  console.error('ERROR: ANTHROPIC_API_KEY is not set.')
  console.error('Copy server/.env.example to server/.env and add your key.')
  process.exit(1)
}

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const app = express()
const PORT = process.env.PORT ?? 3001

app.use(cors({
  origin: process.env.CORS_ORIGIN ?? ['http://localhost:5173', 'http://localhost:3001'],
}))
app.use(express.json())

app.use(express.static(path.join(__dirname, '../../client/dist')))

app.use(router)

app.use((req, res) => {
  if (req.path.startsWith('/api/')) {
    res.status(404).json({ error: 'Not found' })
  } else {
    res.sendFile(path.join(__dirname, '../../client/dist/index.html'))
  }
})

app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err.stack)
  res.status(500).json({ error: 'Internal server error' })
})

app.listen(PORT, () => {
  console.log(`🌶️  Chispa server running on http://localhost:${PORT}`)
})
