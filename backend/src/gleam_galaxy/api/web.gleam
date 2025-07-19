// import gleam/http/response
// import gleam/int
import gleam/http
import gleam/json
import gleam/list
import gleam/otp/task
import gleam_galaxy/api/service
import sqlight
import wisp.{type Request, type Response}

pub fn handle_api_request(req: Request, conn: sqlight.Connection) -> Response {
  use <- wisp.require_method(req, http.Get)
  case list.drop(wisp.path_segments(req), 1) {
    ["search"] -> search_packages(req, conn)
    ["home"] -> get_home(conn)
    ["package", pkg] -> get_package(pkg, conn)
    [] -> {
      json.object([#("message", json.string("Hello API World"))])
      |> json.to_string_builder
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

      let assert Ok(search) =
        sqlight.query(
          sql,
          on: conn,
          with: [sqlight.text(q)],
          expecting: service.decode_search,
        )

      service.encode_search(search)
      |> json.to_string_builder()
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

  let assert Ok(home) =
    sqlight.query(sql, on: conn, with: [], expecting: service.decode_home)

  let assert Ok(home) =
    home
    |> list.first()

  service.encode_home(home)
  |> json.to_string_builder()
  |> wisp.json_response(200)
}

fn get_package(pkg: String, conn: sqlight.Connection) {
  let package_header = task.async(fn() { get_package_header(pkg, conn) })
  let package_history = task.async(fn() { get_package_history(pkg, conn) })

  let package_header = task.await(package_header, 500)
  let package_history = task.await(package_history, 500)

  service.encode_package(package_header, package_history)
  |> json.to_string_builder()
  |> wisp.json_response(200)
}

fn get_package_header(pkg: String, conn: sqlight.Connection) {
  let sql =
    "
  SELECT
    *
  FROM packages
  WHERE package_name = ?
  "

  let assert Ok(response) =
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(pkg)],
      expecting: service.decode_package_record,
    )

  let assert Ok(response) =
    response
    |> list.first()

  response
}

fn get_package_history(pkg: String, conn: sqlight.Connection) {
  let sql =
    "
    SELECT package_name, downloads_yesterday, date(date, '-1 day') as date
    FROM package_daily_downloads
    WHERE package_name = ?
    ORDER BY date DESC
    "

  let assert Ok(response) =
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(pkg)],
      expecting: service.decode_package_history,
    )

  response
}
// TODO - Add CSV export endpoint
