import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type DecodeError}
import gleam_galaxy/models.{type Meta, type Statistics}

// Max Updated At
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
  let meta_decoder = {
    use name <- decode.field("name", decode.string)
    use type_ <- decode.field("type", decode.string)
    decode.success(models.Meta(name, type_))
  }

  let update_data_decoder = {
    use max_updated_at <- decode.field("max_updated_at", decode.string)
    decode.success(UpdateData(max_updated_at))
  }

  let statistics_decoder = {
    use elapsed <- decode.field("elapsed", decode.float)
    use rows_read <- decode.field("rows_read", decode.int)
    use bytes_read <- decode.field("bytes_read", decode.int)
    decode.success(models.Statistics(elapsed, rows_read, bytes_read))
  }

  let decoder = {
    use meta <- decode.field("meta", decode.list(meta_decoder))
    use data <- decode.field("data", decode.list(update_data_decoder))
    use rows <- decode.field("rows", decode.int)
    use statistics <- decode.field("statistics", statistics_decoder)
    decode.success(MaxUpdate(meta, data, rows, statistics))
  }

  decode.run(data, decoder)
}

// Get List of Gleam Packages
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

pub fn decode_gleam_packages(
  data: Dynamic,
) -> Result(ListOfPackages, List(DecodeError)) {
  let meta_decoder = {
    use name <- decode.field("name", decode.string)
    use type_ <- decode.field("type", decode.string)
    decode.success(models.Meta(name, type_))
  }

  let package_name_decoder = {
    use package_name <- decode.field("package_name", decode.string)
    decode.success(PackageName(package_name))
  }

  let statistics_decoder = {
    use elapsed <- decode.field("elapsed", decode.float)
    use rows_read <- decode.field("rows_read", decode.int)
    use bytes_read <- decode.field("bytes_read", decode.int)
    decode.success(models.Statistics(elapsed, rows_read, bytes_read))
  }

  let decoder = {
    use meta <- decode.field("meta", decode.list(meta_decoder))
    use data <- decode.field("data", decode.list(package_name_decoder))
    use rows <- decode.field("rows", decode.int)
    use statistics <- decode.field("statistics", statistics_decoder)
    decode.success(ListOfPackages(meta, data, rows, statistics))
  }

  decode.run(data, decoder)
}
