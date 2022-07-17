const nunjucks = require('nunjucks')
const express = require('express')
const { Client } = require('pg')
const axios = require('axios')

const NODE_ENV = process.env.NODE_ENV || 'production'
const VERSION = process.env.VERSION || '1.0.0'
const WEBSITE_PORT = process.env.WEBSITE_PORT || 3000
const POSTGRES_USER = process.env.POSTGRES_USER || 'postgres'
const POSTGRES_HOST = process.env.POSTGRES_HOST || '0.0.0.0'
const POSTGRES_DATABASE = process.env.POSTGRES_DATABASE || 'postgres'
const POSTGRES_PASSWORD = process.env.POSTGRES_PASSWORD || 'password'
const POSTGRES_PORT = process.env.POSTGRES_PORT || 5432

console.log(`NODE_ENV: ${NODE_ENV} | process.env: ${process.env.NODE_ENV}`)
console.log(`VERSION: ${VERSION} | process.env: ${process.env.VERSION}`)
console.log(`WEBSITE_PORT: ${WEBSITE_PORT} | process.env: ${process.env.WEBSITE_PORT}`)
console.log(`POSTGRES_USER: ${POSTGRES_USER} | process.env: ${process.env.POSTGRES_USER}`)
console.log(`POSTGRES_HOST: ${POSTGRES_HOST} | process.env: ${process.env.POSTGRES_HOST}`)
console.log(`POSTGRES_DATABASE: ${POSTGRES_DATABASE} | process.env: ${process.env.POSTGRES_DATABASE}`)
console.log(`POSTGRES_PASSWORD: ${POSTGRES_PASSWORD} | process.env: ${process.env.POSTGRES_PASSWORD}`)
console.log(`POSTGRES_PORT: ${POSTGRES_PORT} | process.env: ${process.env.POSTGRES_PORT}`)

const app = express()

app.use(express.static('public'))
app.use(express.json())

nunjucks.configure('views', {
    express: app,
    autoescape: false,
    noCache: true
})

app.set('view engine', 'njk')

app.locals.node_env = NODE_ENV
app.locals.version = VERSION

if (NODE_ENV == 'development') {
    const livereload = require('connect-livereload')
    app.use(livereload())
}

const client = new Client({
    user: POSTGRES_USER,
    host: POSTGRES_HOST,
    database: POSTGRES_DATABASE,
    password: POSTGRES_PASSWORD,
    port: POSTGRES_PORT,
})

console.log('client.connect')
client.connect()

app.get('/', async (req, res) => {
    try {
        res.render('index')
        
    } catch (err) {
        return res.json({
            code: err.code, 
            message: err.message
        })
    }
})

/*
    curl http://localhost:3000/vote
*/
app.get('/vote', async (req, res) => {
    let up = await client.query("SELECT value FROM vote WHERE name = 'up'")
    // console.log('up:', up)
    up = Number(up.rows[0].value)
    let down = await client.query("SELECT value FROM vote WHERE name = 'down'")
    down = Number(down.rows[0].value)
    return res.send({ up, down })
})

/*
    curl http://localhost:3000/vote \
        --header 'Content-Type: application/json' \
        --data '{"vote":"up"}'
*/
app.post('/vote', async (req, res) => {
    try {
        console.log('POST /vote: %j', req.body)
        // console.log(req.body.vote)
        let result = await client.query(`UPDATE vote SET value = value + 1 WHERE name = '${req.body.vote}'`)
        // console.log('result:', result)
        return res.send({ success: true, result: 'hello' })
        
    } catch (err) {
        console.log('ERROR: POST /vote: %s', err.message || err.response || err);
        res.status(500).send({ success: false, reason: 'internal error' });
    }
})

app.listen(WEBSITE_PORT, () => {
    console.log(`listening on port ${WEBSITE_PORT}`)
})
