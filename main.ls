require! <[ dns express request faker ]>

const ARBITER_TOKEN = process.env.ARBITER_TOKEN
const PORT = process.env.PORT or 8080

unless ARBITER_TOKEN?
  throw new Error 'Arbiter token undefined'

stores = {}

app = express!

  ..use (req, res, next) !->
    res.header 'Access-Control-Allow-Origin' \*
    next!

  ..get \/ (req, res) !-> res.send '// TODO: Disable UI for containers with no UI'

  ..get \/status (req, res) !-> res.send \active

  ..get \/scan do ->
    lookup = (hostname) ->
      resolve, reject <-! new Promise!
      #console.log "Looking up #hostname"
      err, address <-! dns.lookup hostname
      resolve { hostname, err, address }

    request-macaroon = (target) ->
      resolve, reject <-! new Promise!

      err, res, body <-! request.post do
        url: 'http://arbiter:8080/macaroon'
        form: token: ARBITER_TOKEN, target: target

      resolve { target, err, macaroon: unless err? then body }

    write-data-to-store-forever = (hostname) !->
      store = stores[hostname]
      return unless store?
      console.log "Writing data to #hostname"
      err, res, body <-! request.post do
        url: "http://#hostname:8080/write"
        form:
          macaroon: store.macaroon
          data: JSON.stringify faker.helpers.create-card!

      if err?
        # TODO: If macaroon rejected, request a new one and repeat
        store.being-written-to = false
        return

      write-data-to-store-forever hostname

    (req, res) !->
      lookup-all =
        ["databox-store-mock-#i" for i til 100]
        |> (.map lookup)
        |> Promise.all

      results <-! lookup-all.then

      valid-hostnames =
        results
        |> (.filter (.address?))
        |> (.map (.hostname))

      request-all-macaroons =
        valid-hostnames
        |> (.map request-macaroon)
        |> Promise.all

      results <-! request-all-macaroons.then

      results
        |> (.filter (.macaroon?))
        |> (.map -> stores.{}[it.target].macaroon = it.macaroon; it.target )
        |> JSON.stringify
        |> res.send

      for hostname, store of stores
        continue if store.being-written-to
        store.being-written-to = true
        write-data-to-store-forever hostname

  ..listen PORT
