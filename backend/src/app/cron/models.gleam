import app/error
import app/models.{type Meta, type Statistics}
import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/hackney
import gleam/hexpm
import gleam/http/request
import gleam/json
import gleam/result

pub type UpdateData {
  UpdateData(max_updated_at: String)
}

pub type MaxUpdate {
  MaxUpdate(
    meta: List(Meta),
    data: List(UpdateData),
    rows: Int,
    statistics: Statistics,
  )
}

pub fn decode_max_package_updated_at(
  data: Dynamic,
) -> Result(MaxUpdate, List(DecodeError)) {
  dyn.decode4(
    MaxUpdate,
    dyn.field(
      "meta",
      dyn.list(dyn.decode2(
        Meta,
        dyn.field("name", dyn.string),
        dyn.field("type", dyn.string),
      )),
    ),
    dyn.field(
      "data",
      dyn.list(dyn.decode1(UpdateData, dyn.field("max_updated_at", dyn.string))),
    ),
    dyn.field("rows", dyn.int),
    dyn.field(
      "statistics",
      dyn.decode3(
        Statistics,
        dyn.field("elapsed", dyn.float),
        dyn.field("rows_read", dyn.int),
        dyn.field("bytes_read", dyn.int),
      ),
    ),
  )(data)
}

// Get Gleam Packages
pub type PackageName {
  PackageName(package: String)
}

pub type ListOfPackages {
  ListOfPackages(
    meta: List(Meta),
    data: List(PackageName),
    rows: Int,
    statistics: Statistics,
  )
}

fn decode_gleam_packages(
  data: Dynamic,
) -> Result(ListOfPackages, List(DecodeError)) {
  io.println("START DECODE")
  dyn.decode4(
    ListOfPackages,
    dyn.field(
      "meta",
      dyn.list(dyn.decode2(
        Meta,
        dyn.field("name", dyn.string),
        dyn.field("type", dyn.string),
      )),
    ),
    dyn.field(
      "data",
      dyn.list(dyn.decode1(PackageName, dyn.field("package_name", dyn.string))),
    ),
    dyn.field("rows", dyn.int),
    dyn.field(
      "statistics",
      dyn.decode3(
        Statistics,
        dyn.field("elapsed", dyn.float),
        dyn.field("rows_read", dyn.int),
        dyn.field("bytes_read", dyn.int),
      ),
    ),
  )(data)
}
