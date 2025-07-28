import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http
import gleam/json
import gleam/list

import gleam/string
import gleam/string_tree
import gleam_galaxy/api/service
import gleam_galaxy/job/job
import sqlight
import wisp.{type Request, type Response}

pub fn handle_api_request(
  req: Request,
  conn: sqlight.Connection,
  hex_key: String,
  cron_secret: String,
) -> Response {
  use <- wisp.require_method(req, http.Get)
  case list.drop(wisp.path_segments(req), 1) {
    ["search"] -> search_packages(req, conn)
    ["home"] -> get_home(conn)
    ["package", pkg] -> get_package(pkg, conn)
    ["cron"] -> start_cron(req, conn, hex_key, cron_secret)
    [] -> {
      json.object([#("message", json.string("Hello API World"))])
      |> json.to_string
      |> string_tree.from_string
      |> wisp.json_response(200)
    }
    _ -> {
      wisp.response(404)
    }
  }
}

fn search_packages(req, conn: sqlight.Connection) -> Response {
  case wisp.get_query(req) {
    [#("query", q)] -> {
      let sql =
        "
        SELECT
          p.package_name,
          p.description,
          p.downloads_all_time
        FROM packages AS p
        JOIN packages_fts AS fts
        ON p.rowid = fts.rowid
        WHERE
          fts.packages_fts MATCH ? || '*'
        ORDER BY
          (fts.rank * log2(2 + p.downloads_all_time))
        LIMIT 5;
    "

      let search_decoder = {
        use package_name <- decode.then(decode.at([0], decode.string))
        use description <- decode.then(decode.at([1], decode.string))
        use downloads_all_time <- decode.then(decode.at([2], decode.int))
        decode.success(service.SearchRecord(
          package_name,
          description,
          downloads_all_time,
        ))
      }

      let assert Ok(search) =
        sqlight.query(
          sql,
          on: conn,
          with: [sqlight.text(q)],
          expecting: search_decoder,
        )

      service.encode_search(search)
      |> json.to_string
      |> string_tree.from_string
      |> wisp.json_response(200)
    }
    _ -> {
      wisp.response(400)
    }
  }
}

fn get_home(conn: sqlight.Connection) -> Response {
  let sql =
    "
    SELECT
      COUNT(DISTINCT package_name) AS num_packages,
      CAST(SUM(downloads_all_time) AS INT) AS total_downloads
    FROM packages;
  "

  let home_decoder = {
    use num_packages <- decode.then(decode.at([0], decode.int))
    use total_downloads <- decode.then(decode.at([1], decode.int))
    decode.success(service.HomeRecord(num_packages, total_downloads))
  }

  let assert Ok(home) =
    sqlight.query(sql, on: conn, with: [], expecting: home_decoder)

  let assert Ok(home) =
    home
    |> list.first()

  service.encode_home(home)
  |> json.to_string
  |> string_tree.from_string
  |> wisp.json_response(200)
}

fn start_cron(
  req: Request,
  conn: sqlight.Connection,
  hex_key: String,
  cron_secret: String,
) -> Response {
  case wisp.get_query(req) {
    [#("secret", secret)] if secret == cron_secret -> {
      let _ = process.spawn(fn() { job.start_sync(hex_key, conn) })
      json.object([#("message", json.string("Cron job started"))])
      |> json.to_string
      |> string_tree.from_string
      |> wisp.json_response(200)
    }
    _ -> {
      json.object([#("error", json.string("Invalid secret"))])
      |> json.to_string
      |> string_tree.from_string
      |> wisp.json_response(401)
    }
  }
}

fn get_package(pkg: String, conn: sqlight.Connection) -> Response {
  echo "Fetching package" <> pkg
  case get_package_header(pkg, conn) {
    Ok(package_header) -> {
      let package_history = get_package_history(pkg, conn)
      service.encode_package(package_header, package_history)
      |> json.to_string
      |> string_tree.from_string
      |> wisp.json_response(200)
    }
    Error(_) -> wisp.response(404)
  }
}

fn get_package_header(
  pkg: String,
  conn: sqlight.Connection,
) -> Result(service.PackageRecord, Nil) {
  echo "header"
  let sql =
    "
  SELECT
    p.package_name,
    p.hex_url,
    p.description,
    p.licenses,
    p.repository_url,
    p.owners,
    p.downloads_all_time,
    p.hex_updated_at,
    p.hex_inserted_at
  FROM packages p
  WHERE p.package_name = ?;
  "

  let string_to_list = fn(data) {
    let decoder =
      decode.string
      |> decode.map(fn(str) {
        case str {
          "" -> []
          _ -> string.split(str, ",")
        }
      })
    decode.run(data, decoder)
  }

  let string_list_decoder =
    decode.new_primitive_decoder("StringList", fn(data) {
      case string_to_list(data) {
        Ok(list) -> Ok(list)
        Error(_) -> Error([])
      }
    })

  let package_decoder = {
    use package_name <- decode.then(decode.at([0], decode.string))
    use hex_url <- decode.then(decode.at([1], decode.string))
    use description <- decode.then(decode.at([2], decode.string))
    use licenses <- decode.then(decode.at([3], string_list_decoder))
    use repository_url <- decode.then(decode.at([4], decode.string))
    use owners <- decode.then(decode.at([5], string_list_decoder))
    use downloads_all_time <- decode.then(decode.at([6], decode.int))
    use hex_updated_at <- decode.then(decode.at([7], decode.string))
    use hex_inserted_at <- decode.then(decode.at([8], decode.string))
    decode.success(service.PackageRecord(
      package_name,
      hex_url,
      description,
      licenses,
      repository_url,
      owners,
      downloads_all_time,
      hex_updated_at,
      hex_inserted_at,
    ))
  }

  let result =
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(pkg)],
      expecting: package_decoder,
    )

  echo result

  case result {
    Ok(records) ->
      case list.first(records) {
        Ok(record) -> Ok(record)
        Error(_) -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}

fn get_package_history(pkg: String, conn: sqlight.Connection) {
  let sql =
    "
    SELECT package_name, downloads_yesterday, date(date, '-1 day') as date
    FROM package_daily_downloads
    WHERE package_name = ?
    ORDER BY date DESC
    "

  let history_decoder = {
    use package_name <- decode.then(decode.at([0], decode.string))
    use downloads <- decode.then(decode.at([1], decode.int))
    use date <- decode.then(decode.at([2], decode.string))
    decode.success(service.PackageHistory(package_name, downloads, date))
  }

  let assert Ok(response) =
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(pkg)],
      expecting: history_decoder,
    )

  response
}
