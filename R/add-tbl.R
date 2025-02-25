#' Add tables to a [`dm`]
#'
#' @description
#' `cdm_add_tbl()` adds one or more tibbles to a [`dm`].
#' It uses [mutate()] semantics.
#'
#' @return The inital `dm` with the additional table(s).
#'
#' @seealso [cdm_rm_tbl()]
#'
#' @param dm A [`dm`] object
#' @param ... One or more tibbles to add to the `dm`.
#'   If no explicit name is given, the name of the expression is used.
#' @inheritParams vctrs::vec_as_names
#'
#' @export
cdm_add_tbl <- function(dm, ..., repair = "check_unique") {
  check_dm(dm)

  orig_tbls <- src_tbls(dm)

  new_names <- names(exprs(..., .named = TRUE))
  new_tables <- list(...)

  check_new_tbls(dm, new_tables)

  old_names <- src_tbls(dm)
  all_names <- vctrs::vec_as_names(c(old_names, new_names), repair = repair)

  new_old_names <- all_names[seq_along(old_names)]

  selected <- set_names(old_names, new_old_names)
  dm <- cdm_select_tbl_impl(dm, selected)

  new_names <- all_names[seq2(length(old_names) + 1, length(all_names))]
  cdm_add_tbl_impl(dm, new_tables, new_names)
}

cdm_add_tbl_impl <- function(dm, tbls, table_name) {
  def <- cdm_get_def(dm)

  def_0 <- def[rep_along(table_name, NA_integer_), ]
  def_0$table <- table_name
  def_0$data <- tbls

  new_dm3(vctrs::vec_rbind(def, def_0))
}

#' Remove tables from a [`dm`]
#'
#' @description
#' Removes one or more tibbles from a [`dm`].
#'
#' @return The inital `dm` without the removed table(s).
#'
#' @seealso [cdm_add_tbl()], [cdm_select_tbl()]
#'
#' @param dm A [`dm`] object
#' @param ... One or more unquoted tibble names to remove from the `dm`.
#'
#' @export
cdm_rm_tbl <- function(dm, ...) {
  check_dm(dm)

  table_names <-
    ensyms(..., .named = FALSE) %>%
    map_chr(~ as_name(.))

  check_correct_input(dm, table_names)

  cdm_select_tbl(dm, -one_of(!!!table_names))
}


check_new_tbls <- function(dm, tbls) {
  orig_tbls <- cdm_get_tables(dm)

  # are all new tables on the same source as the original ones?
  if (has_length(orig_tbls) && !all_same_source(c(orig_tbls[1], tbls))) {
    abort_not_same_src()
  }
}

