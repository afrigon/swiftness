const express = require('express')
const app = express()
const server = require('http').createServer(app)
const fs = require('fs')
const path = require('path')

app.disable('x-powered-by')

// reload data whe the json file changes
let data = require("./data.json")
fs.watch('data.json', (eventType, filename) => {
    data = require('./data.json')
})

app.get('/', (req, res) => res.sendFile(path.join(__dirname, 'index.html')))
app.use('/static', express.static('static', { maxAge: '7d' }))

// list nes games
app.get('/api/nes', (req, res) => res.json(data))

// get nes game
app.get('/api/nes/:id', (req, res, next) => {
    const item = data.find(n => n.id == req.params.id)
    if (!item) return next()
    return res.json(item)
})

// 404
app.use((req, res) => res.status(404).send('404'))

server.listen(8080)

