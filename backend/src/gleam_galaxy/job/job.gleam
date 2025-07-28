import gleam/dict

import gleam/dynamic/decode
import gleam/erlang/process
import gleam/float
import gleam/hackney
import gleam/hexpm
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option
import gleam/order.{Eq, Gt, Lt}
import gleam/result
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}
import gleam/uri
import gleam_galaxy/error.{type Error}
import gleam_galaxy/models.{type State}
import sqlight
import wisp

/// Start Cron Job to Sync Hex Packages
pub fn start_sync(hex_key: String, conn: sqlight.Connection) {
  wisp.log_info("Start Scheduler")

  wisp.log_info("Latest TS")

  let state =
    models.State(
      page: 1,
      last_updated_at: timestamp.system_time(),
      hex_key: hex_key,
      db_connection: conn,
      current_time: timestamp.system_time(),
    )

  // Periodic actor takes a function, and sync needs state. Run every 10hr to get 2x a day
  // 36_000_000
  sync_data(state)
}

// TODO - Change to SQLITE instead of TB

/// Job that Syncs Hex Package Data
fn sync_data(state: State) -> Nil {
  wisp.log_info("Start Sync Data")
  let last_updated_at = case get_max_package_updated_at(state.db_connection) {
    Ok(t) -> {
      wisp.log_info("Got last_updated_at")
      t
    }
    Error(_) ->
      timestamp.system_time()
      |> timestamp.add(duration.seconds(-24 * 60 * 60))
  }

  let state = models.State(..state, last_updated_at: last_updated_at)
  wisp.log_info(
    "Start Cron Job at: "
    <> timestamp.to_rfc3339(state.current_time, calendar.utc_offset),
  )
  wisp.log_info(
    "Max Updated At: "
    <> timestamp.to_rfc3339(state.last_updated_at, calendar.utc_offset),
  )

  // Sync Updates
  wisp.log_info("===== Sync Updates =====")
  let _ = sync_updates(state)

  // Sync Downloads
  wisp.log_info("===== Sync Downloads =====")
  let _ = sync_downloads(state)

  wisp.log_info(
    "Cron Job Completed at: "
    <> timestamp.to_rfc3339(state.current_time, calendar.utc_offset),
  )
  Nil
}

/// Get Max Package Updated At Returns max time from packages table minus 8 hours in case a job failed
pub fn get_max_package_updated_at(conn: sqlight.Connection) {
  wisp.log_info("Max TS")
  let sql =
    "
    SELECT MAX(hex_updated_at) AS max_updated_at FROM packages
    "

  echo sql

  let max_update =
    sqlight.query(
      sql,
      on: conn,
      with: [],
      expecting: decode.at([0], decode.string),
    )

  let max_update = case max_update {
    Ok(t) -> t
    Error(e) -> {
      echo "Error fetching max package updated at: "
      echo e
      // Return a list with the current system time as a fallback for consistency
      [timestamp.system_time() |> timestamp.to_rfc3339(calendar.utc_offset)]
    }
  }

  echo max_update
  let init =
    timestamp.system_time()
    |> timestamp.add(duration.seconds(-5 * 365 * 24 * 60 * 60))

  let max_time = case list.first(max_update) {
    Ok(t) -> timestamp.parse_rfc3339(t)
    Error(_) ->
      init
      |> Ok()
  }

  wisp.log_info("Max TS Done")
  max_time
  |> result.unwrap(init)
  |> timestamp.add(duration.seconds(-12 * 60 * 60))
  |> Ok()
}

/// Sync Package Updates ==========================================================================
fn sync_updates(state: State) {
  use packages <- result.try(fetch_packages(state))
  // TESTING: Limit to first 3 packages to avoid hitting API too much
  // let packages = list.take(packages, 1)
  io.println("LIST LENGTH:" <> int.to_string(list.length(packages)))

  use min_date <- result.try(min_timestamp(packages))
  let start = timestamp.system_time()

  let pkgs =
    list.map(packages, fn(pkg) {
      process.sleep(1000)
      process_package(pkg, state)
    })

  io.println("pkgs LENGTH:" <> int.to_string(list.length(pkgs)))

  // io.debug(list.length(pkgs))
  let end_time = timestamp.system_time()
  let diff = timestamp.difference(start, end_time)
  let diff_seconds = duration.to_seconds(diff) |> float.round
  io.println("Run Time ----> " <> int.to_string(diff_seconds) <> " seconds")
  process.sleep(30_000)

  // If min package updated at greater than or equal to max tb date
  // then keep looping as have not seen all packages
  let _ = case timestamp.compare(min_date, state.last_updated_at) {
    Gt | Eq -> {
      io.println(
        "Gt Eq"
        <> " Packages Date"
        <> timestamp.to_rfc3339(min_date, calendar.utc_offset)
        <> " Min Date TB: "
        <> timestamp.to_rfc3339(state.last_updated_at, calendar.utc_offset),
      )
      sync_updates(models.State(..state, page: state.page + 1))
    }
    Lt -> {
      io.println(
        "LT"
        <> " Packages Date"
        <> timestamp.to_rfc3339(min_date, calendar.utc_offset)
        <> " Min Date TB: "
        <> timestamp.to_rfc3339(state.last_updated_at, calendar.utc_offset),
      )
      Ok(Nil)
    }
  }

  Ok(Nil)
}

fn min_timestamp(packages: List(hexpm.Package)) -> Result(Timestamp, Error) {
  // Assume the packages are sorted desc
  let assert Ok(first) = list.first(packages)
  let assert Ok(last) = list.last(packages)
  case timestamp.compare(first.updated_at, last.updated_at) {
    Gt | Eq -> Nil
    Lt -> panic as "PACKAGES NOT SORTED CORRECTLY"
  }

  case list.last(packages) {
    Ok(last) -> last.updated_at
    Error(_) -> timestamp.from_unix_seconds(0)
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
    json.parse(from: response.body, using: decode.list(hexpm.package_decoder()))
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

  json.parse(from: response.body, using: hexpm.release_decoder())
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

  let hex_updated_at =
    pkg.updated_at |> timestamp.to_rfc3339(calendar.utc_offset)
  let hex_inserted_at =
    pkg.inserted_at |> timestamp.to_rfc3339(calendar.utc_offset)
  let inserted_at =
    timestamp.system_time() |> timestamp.to_rfc3339(calendar.utc_offset)
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
    expecting: decode.dynamic,
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
  let hex_updated_at =
    release.updated_at |> timestamp.to_rfc3339(calendar.utc_offset)
  let hex_inserted_at =
    release.inserted_at |> timestamp.to_rfc3339(calendar.utc_offset)
  let inserted_at =
    timestamp.system_time() |> timestamp.to_rfc3339(calendar.utc_offset)

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
    expecting: decode.dynamic,
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
    json.parse(from: response.body, using: hexpm.package_decoder())
    |> result.map_error(error.JsonDecodeError),
  )

  Ok(package)
}

// Sync Downloads =======================================================================

fn sync_downloads(state: State) {
  let packages = case get_list_gleam_packages_sqlite(state.db_connection) {
    Ok(packages) -> {
      // TESTING: Limit to first 5 packages to avoid hitting API too much
      // let packages = list.take(packages, 1) // Uncomment for testing, e.g., list.take(packages, 1)
      { int.to_string(list.length(packages)) <> " Packages to Get Downloads" }
      |> io.println()
      packages
    }
    Error(_) -> []
  }

  let start = timestamp.system_time()

  let download_results =
    list.map(packages, fn(pkg) {
      process.sleep(1000)
      io.println("Getting downloads - " <> pkg)
      fetch_package(pkg, state.hex_key)
    })

  let _ =
    list.each(download_results, fn(result) {
      insert_package_daily_downloads_sqlite(result, state.db_connection)
    })

  let end_time = timestamp.system_time()
  let diff = timestamp.difference(start, end_time)
  let diff_seconds = duration.to_seconds(diff) |> float.round
  io.println("Run Time ----> " <> int.to_string(diff_seconds) <> " seconds")
}

fn get_list_gleam_packages_sqlite(conn: sqlight.Connection) {
  let sql =
    "SELECT DISTINCT package_name FROM packages ORDER BY downloads_all_time DESC"

  use packages <- result.try(
    sqlight.query(sql, on: conn, with: [], expecting: decode.string)
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
        timestamp.system_time()
        |> timestamp.to_calendar(calendar.utc_offset)
        |> fn(cal) {
          { cal.0 }.year |> int.to_string
          <> "-"
          <> format_month({ cal.0 }.month)
          <> "-"
          <> format_day({ cal.0 }.day)
        }

      let inserted_at =
        timestamp.system_time()
        |> timestamp.to_rfc3339(calendar.utc_offset)

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
        expecting: decode.dynamic,
      )
      |> result.map(fn(_) { Nil })
      |> result.unwrap(Nil)
    }
    Error(_) -> Nil
  }
}

fn format_month(month: calendar.Month) -> String {
  case month {
    calendar.January -> "01"
    calendar.February -> "02"
    calendar.March -> "03"
    calendar.April -> "04"
    calendar.May -> "05"
    calendar.June -> "06"
    calendar.July -> "07"
    calendar.August -> "08"
    calendar.September -> "09"
    calendar.October -> "10"
    calendar.November -> "11"
    calendar.December -> "12"
  }
}

fn format_day(day: Int) -> String {
  case day < 10 {
    True -> "0" <> int.to_string(day)
    False -> int.to_string(day)
  }
}
