#' Number of rows
#'
#' Returns a named vector with the number of rows for each table.
#'
#' @param dm A [`dm`] object
#' @export
cdm_nrow <- function(dm) {
  map_dbl(cdm_get_tables(dm), ~ as.numeric(pull(collect(count(.)))))
}

get_by <- function(dm, lhs_name, rhs_name) {
  if (cdm_has_fk(dm, !!lhs_name, !!rhs_name)) {
    lhs_col <- cdm_get_fk(dm, !!lhs_name, !!rhs_name)
    rhs_col <- cdm_get_pk(dm, !!rhs_name)
  } else if (cdm_has_fk(dm, !!rhs_name, !!lhs_name)) {
    lhs_col <- cdm_get_pk(dm, !!lhs_name)
    rhs_col <- cdm_get_fk(dm, !!rhs_name, !!lhs_name)
  } else {
    abort_tables_not_neighbours(lhs_name, rhs_name)
  }

  # Construct a `by` argument of the form `c("lhs_col[1]" = "rhs_col[1]", ...)`
  # as required by `*_join()`
  by <- rhs_col
  names(by) <- lhs_col
  by
}
