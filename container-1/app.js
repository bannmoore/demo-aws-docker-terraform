const express = require('express')
const app = express()

app.use((req, res, next) => req.accepts('text') ? next() : res.status(406).end())
app.get('/endpoint-1', (req, res) => res.send('endpoint-1'))
app.get('/endpoint-2', (req, res) => res.send('endpoint-2'))
app.get('/health', (req, res) => res.send('ok'))
app.use((req, res) => res.status(404).send('not found'))

app.listen(process.env.PORT || 3000, function () {
  const { address, port } = this.address()
  process.stdout.write(`Listening on ${address}:${port}...\n`)
})