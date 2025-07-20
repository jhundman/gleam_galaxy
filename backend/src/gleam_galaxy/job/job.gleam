import birl.{type Time}
import birl/duration
import gleam/dict
import gleam/dynamic as dyn
import gleam/erlang/process
import gleam/hackney
import gleam/hexpm
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option
import gleam/order.{Eq, Gt, Lt}
import gleam/otp/task
import gleam/result
import gleam/uri
import gleam_galaxy/error.{type Error}
import gleam_galaxy/models.{type State}
import shakespeare/actors/periodic.{Ms, start}
import sqlight
import wisp

/// Start Cron Job to Sync Hex Packages
pub fn start_sync(hex_key: String, conn: sqlight.Connection) {
  wisp.log_info("Start Scheduler")

  io.println("\nLatest TS")

  let state =
    models.State(
      page: 1,
      last_updated_at: birl.utc_now(),
      hex_key: hex_key,
      db_connection: conn,
      current_time: birl.utc_now(),
    )

  // Periodic actor takes a function, and sync needs state. Run every 10hr to get 2x a day
  // 36_000_000
  let cron = fn() { sync_data(state) }
  start(do: cron, every: Ms(36_000_000))
}

// TODO - Change to SQLITE instead of TB

/// Job that Syncs Hex Package Data
fn sync_data(state: State) -> Nil {
  let last_updated_at = case get_max_package_updated_at(state.db_connection) {
    Ok(t) -> t
    Error(_) ->
      birl.utc_now()
      // |> birl.subtract(duration.years(5))
      |> birl.subtract(duration.hours(24))
  }

  let state = models.State(..state, last_updated_at: last_updated_at)
  wisp.log_info("Start Cron Job at: " <> state.current_time |> birl.to_iso8601)
  wisp.log_info("Max Updated At: " <> state.last_updated_at |> birl.to_iso8601)

  // Sync Updates
  wisp.log_info("===== Sync Updates =====")
  let _ = sync_updates(state)

  // Sync Downloads
  wisp.log_info("===== Sync Downloads =====")
  let _ = sync_downloads(state)

  wisp.log_info(
    "Cron Job Completed at: " <> state.current_time |> birl.to_iso8601,
  )
  Nil
}

/// Get Max Package Updated At Returns max time from packages table minus 8 hours in case a job failed
pub fn get_max_package_updated_at(conn: sqlight.Connection) {
  let sql =
    "
    SELECT MAX(hex_updated_at) AS max_updated_at FROM packages
    "
  let assert Ok(max_update) =
    sqlight.query(
      sql,
      on: conn,
      with: [],
      expecting: dyn.element(0, dyn.string),
    )

  let init =
    birl.utc_now()
    |> birl.subtract(duration.years(5))

  let max_time = case list.first(max_update) {
    Ok(t) -> birl.parse(t)
    Error(_) ->
      init
      |> Ok()
  }

  max_time
  |> result.unwrap(init)
  |> birl.subtract(duration.hours(12))
  |> Ok()
}

/// Sync Package Updates ==========================================================================
fn sync_updates(state: State) {
  use packages <- result.try(fetch_packages(state))
  // TESTING: Limit to first 3 packages to avoid hitting API too much
  let packages = list.take(packages, 1)
  io.println("LIST LENGTH:" <> int.to_string(list.length(packages)))

  use min_date <- result.try(min_timestamp(packages))
  let start = birl.utc_now()

  // 100 / chunk size = num_tasks
  let chunks = list.sized_chunk(packages, 100)
  // io.println("Chunk LENGTH:" <> int.to_string(list.length(chunks)))

  let handles =
    list.map(chunks, fn(chunk) {
      task.async(fn() {
        list.map(chunk, fn(pkg) {
          process.sleep(1000)
          process_package(pkg, state)
        })
      })
    })

  let pkgs =
    list.fold(handles, [], fn(acc, handle) {
      let result = task.await(handle, 600_000)
      list.concat([result, acc])
    })

  io.println("pkgs LENGTH:" <> int.to_string(list.length(pkgs)))

  // io.debug(list.length(pkgs))
  io.println(
    "Run Time ----> " <> birl.legible_difference(birl.utc_now(), start),
  )
  process.sleep(30_000)

  // If min package updated at greater than or equal to max tb date
  // then keep looping as have not seen all packages
  let _ = case birl.compare(min_date, state.last_updated_at) {
    Gt | Eq -> {
      io.println(
        "Gt Eq"
        <> " Packages Date"
        <> birl.to_iso8601(min_date)
        <> " Min Date TB: "
        <> birl.to_iso8601(state.last_updated_at),
      )
      sync_updates(models.State(..state, page: state.page + 1))
    }
    Lt -> {
      io.println(
        "LT"
        <> " Packages Date"
        <> birl.to_iso8601(min_date)
        <> " Min Date TB: "
        <> birl.to_iso8601(state.last_updated_at),
      )
      Ok(Nil)
    }
  }

  Ok(Nil)
}

fn min_timestamp(packages: List(hexpm.Package)) -> Result(Time, Error) {
  // Assume the packages are sorted desc
  let assert Ok(first) = list.first(packages)
  let assert Ok(last) = list.last(packages)
  case birl.compare(first.updated_at, last.updated_at) {
    Gt | Eq -> Nil
    Lt -> panic as "PACKAGES NOT SORTED CORRECTLY"
  }

  case list.last(packages) {
    Ok(last) -> last.updated_at
    Error(_) -> birl.from_unix(0)
  }
  |> Ok()
}

fn fetch_packages(state: State) -> Result(List(hexpm.Package), Error) {
  io.println("Page: " <> int.to_string(state.page))
  use response <- result.try(
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path("/api/packages")
    |> request.set_query([
      #("sort", "updated_at"),
      #("page", int.to_string(state.page)),
    ])
    |> request.prepend_header("authorization", state.hex_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )
  use all_packages <- result.try(
    json.decode(response.body, using: dyn.list(of: hexpm.decode_package))
    |> result.map_error(error.JsonDecodeError),
  )
  Ok(all_packages)
}

fn process_package(package: hexpm.Package, state: State) {
  use releases <- result.try(lookup_gleam_releases(package, state.hex_key))
  case releases {
    [] -> {
      io.println(package.name <> " - NO GLEAM RELEASES")
      Ok(state)
    }
    _ -> {
      io.println("UPDATE - " <> package.name)
      let _ = insert_updates(package, releases, state)
      Ok(state)
    }
  }
}

fn insert_updates(
  package: hexpm.Package,
  releases: List(hexpm.Release),
  state: State,
) {
  let _ = insert_package_sqlite(package, state.db_connection)
  let _ = insert_releases_sqlite(package.name, releases, state.db_connection)
  Ok(Nil)
}

fn lookup_gleam_releases(
  package: hexpm.Package,
  hex_key: String,
) -> Result(List(hexpm.Release), Error) {
  use releases <- result.try(
    list.try_map(package.releases, lookup_release(_, hex_key)),
  )
  releases
  |> list.filter(fn(release) {
    list.contains(release.meta.build_tools, "gleam")
  })
  |> Ok
}

fn lookup_release(
  release: hexpm.PackageRelease,
  hex_key: String,
) -> Result(hexpm.Release, Error) {
  let assert Ok(url) = uri.parse(release.url)

  use response <- result.try(
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path(url.path)
    |> request.prepend_header("authorization", hex_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )

  case response.status > 299 {
    True ->
      io.print_error(
        "RELEASE REQUEST: "
        <> url.path
        <> " "
        <> release.version
        <> " "
        <> int.to_string(response.status)
        <> response.body,
      )
    _ -> Nil
  }

  json.decode(response.body, using: hexpm.decode_release)
  |> result.map_error(error.JsonDecodeError)
}

fn insert_package_sqlite(pkg: hexpm.Package, conn: sqlight.Connection) {
  let downloads =
    pkg.downloads
    |> dict.get("all")
    |> result.unwrap(0)

  let repo_url =
    pkg.meta.links
    |> dict.get("Repository")
    |> result.unwrap("")

  let hex_updated_at = pkg.updated_at |> birl.to_iso8601()
  let hex_inserted_at = pkg.inserted_at |> birl.to_iso8601()
  let inserted_at = birl.utc_now() |> birl.to_iso8601()
  let licenses_json =
    json.array(pkg.meta.licenses, of: json.string) |> json.to_string()

  let sql =
    "
    INSERT OR REPLACE INTO packages (
      package_name, hex_url, description, licenses, repository_url,
      downloads_all_time, hex_updated_at, hex_inserted_at, inserted_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  "

  sqlight.query(
    sql,
    on: conn,
    with: [
      sqlight.text(pkg.name),
      sqlight.text(option.unwrap(pkg.html_url, "")),
      sqlight.text(option.unwrap(pkg.meta.description, "")),
      sqlight.text(licenses_json),
      sqlight.text(repo_url),
      sqlight.int(downloads),
      sqlight.text(hex_updated_at),
      sqlight.text(hex_inserted_at),
      sqlight.text(inserted_at),
    ],
    expecting: dyn.dynamic,
  )
  |> result.map(fn(_) { Nil })
  |> result.unwrap(Nil)
}

fn insert_releases_sqlite(
  package_name: String,
  releases: List(hexpm.Release),
  conn: sqlight.Connection,
) {
  list.each(releases, fn(release) {
    insert_release_sqlite(package_name, release, conn)
  })
}

fn insert_release_sqlite(
  package_name: String,
  release: hexpm.Release,
  conn: sqlight.Connection,
) {
  let hex_updated_at = release.updated_at |> birl.to_iso8601()
  let hex_inserted_at = release.inserted_at |> birl.to_iso8601()
  let inserted_at = birl.utc_now() |> birl.to_iso8601()

  let sql =
    "
    INSERT OR REPLACE INTO package_releases (
      package_name, release, release_downloads, url,
      hex_updated_at, hex_inserted_at, inserted_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
  "

  sqlight.query(
    sql,
    on: conn,
    with: [
      sqlight.text(package_name),
      sqlight.text(release.version),
      sqlight.int(release.downloads),
      sqlight.text(release.url),
      sqlight.text(hex_updated_at),
      sqlight.text(hex_inserted_at),
      sqlight.text(inserted_at),
    ],
    expecting: dyn.dynamic,
  )
  |> result.map(fn(_) { Nil })
  |> result.unwrap(Nil)
}

pub fn fetch_package(package_name: String, hex_key: String) {
  use response <- result.try(
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path("/api/packages/" <> package_name)
    |> request.prepend_header("authorization", hex_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )

  case response.status > 299 {
    True ->
      io.print_error(
        "Package REQUEST: "
        <> package_name
        <> " "
        <> int.to_string(response.status)
        <> response.body,
      )
    _ -> Nil
  }

  use package <- result.try(
    json.decode(response.body, using: hexpm.decode_package)
    |> result.map_error(error.JsonDecodeError),
  )

  Ok(package)
}

// Sync Downloads =======================================================================

fn sync_downloads(state: State) {
  let packages = case get_list_gleam_packages_sqlite(state.db_connection) {
    Ok(packages) -> {
      // TESTING: Limit to first 5 packages to avoid hitting API too much
      let limited_packages = list.take(packages, 1)
      {
        int.to_string(list.length(limited_packages))
        <> " Packages to Get Downloads"
      }
      |> io.println()
      limited_packages
    }
    Error(_) -> []
  }

  let start = birl.utc_now()

  let chunk_size = list.length(packages) / 1
  let chunks = list.sized_chunk(packages, chunk_size)

  let handles =
    list.map(chunks, fn(chunk) {
      task.async(fn() {
        list.map(chunk, fn(pkg) {
          process.sleep(1000)
          io.println("Getting downloads - " <> pkg)
          fetch_package(pkg, state.hex_key)
        })
      })
    })

  let download_results =
    list.fold(handles, [], fn(acc, handle) {
      let result = task.await(handle, 3_600_000)
      list.concat([result, acc])
    })

  let _ =
    list.each(download_results, fn(result) {
      insert_package_daily_downloads_sqlite(result, state.db_connection)
    })

  io.println(
    "Run Time ----> " <> birl.legible_difference(birl.utc_now(), start),
  )
}

fn get_list_gleam_packages_sqlite(conn: sqlight.Connection) {
  let sql =
    "SELECT DISTINCT package_name FROM packages ORDER BY downloads_all_time DESC"

  use packages <- result.try(
    sqlight.query(
      sql,
      on: conn,
      with: [],
      expecting: dyn.element(0, dyn.string),
    )
    |> result.map_error(error.DatabaseError),
  )

  Ok(packages)
}

fn insert_package_daily_downloads_sqlite(
  package_result: Result(hexpm.Package, Error),
  conn: sqlight.Connection,
) {
  case package_result {
    Ok(package) -> {
      let downloads_yesterday =
        package.downloads
        |> dict.get("day")
        |> result.unwrap(0)

      let date =
        birl.utc_now()
        |> birl.to_naive_date_string()

      let inserted_at =
        birl.utc_now()
        |> birl.to_iso8601()

      let sql =
        "
        INSERT OR REPLACE INTO package_daily_downloads (
          package_name, date, downloads_yesterday, inserted_at
        ) VALUES (?, ?, ?, ?)
        "

      sqlight.query(
        sql,
        on: conn,
        with: [
          sqlight.text(package.name),
          sqlight.text(date),
          sqlight.int(downloads_yesterday),
          sqlight.text(inserted_at),
        ],
        expecting: dyn.dynamic,
      )
      |> result.map(fn(_) { Nil })
      |> result.unwrap(Nil)
    }
    Error(_) -> Nil
  }
}
