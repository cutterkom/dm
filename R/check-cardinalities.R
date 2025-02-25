#' Test if the relation between two tables of a data model meet the requirements
#'
#' @description All `check_cardinality()` functions test, if the `pk_column` is a unique key for `parent_table` and if
#' the set of values of `fk_column` of `child_table` is a subset of the set of values of `pk_column`.
#' Furthermore the cardinality of the relation is tested, see below for details.
#'
#' @details All `check_cardinality` functions accept a `parent table` (data frame), a column name of this table,
#' a `child table`, and a column name of the child table. The given column of the `parent table` has to be one of its
#' unique keys (no duplicates allowed).
#' Furthermore, in all cases, the set of values of the child table's column has to be a subset of the set of values of
#' the parent table's column.
#'
#' The cardinality specifications `0_n`, `1_n`, `0_1`, `1_1` refer to the expected relation that the child table has with the parent table.
#' The numbers `0`, `1` and `n` refer to the number of values in the child table's column that correspond to each value of the
#' parent table's column. `n` means more than one in this context, with no upper limit.
#'
#' `0_n` means, that for each value of the `pk_column`, minimally `0` and maximally
#' `n` values have to correspond to it in the child table's column (which translates to no further restriction).
#'
#' `1_n` means, that for each value of the `pk_column`, minimally `1` and maximally
#' `n` values have to correspond to it in the child table's column. This means that there is a "surjective" relation from the child table
#' to the parent table w.r.t. the specified columns, i.e. for each parent table column value there exists at least one equal child table column value.
#'
#' `0_1` means, that for each value of the `pk_column`, minimally `0` and maximally
#' `1` value has to correspond to it in the child table's column. This means that there is a "injective" relation from the child table
#' to the parent table w.r.t. the specified columns, i.e. no parent table column value is addressed multiple times. But not all of the parent table
#' column values have to be referred to.
#'
#' `1_1` means, that for each value of the `pk_column`, precisely
#' `1` value has to correspond to it in the child table's column. This means that there is a "bijective" ("injective" AND "surjective") relation
#' between the child table and the parent table w.r.t. the specified columns, i.e. the sets of values of the two columns are equal and
#' there are no duplicates in either of them.
#'
#' @param parent_table Data frame
#' @param pk_column Column of `parent_table` that has to be one of its unique keys.
#' @param child_table Data frame
#' @param fk_column Column of `child_table` that has to be a foreign key to `pk_column` in `parent_table`
#'
#' @name check_cardinality
#'
#' @export
#' @examples
#' d1 <- tibble::tibble(a = 1:5)
#' d2 <- tibble::tibble(c = c(1:5, 5))
#' d3 <- tibble::tibble(c = 1:4)
#' # This does not pass, `c` is not unique key of d2:
#' try(check_cardinality_0_n(d2, c, d1, a))
#'
#' # This passes, multiple values in d2$c are allowed:
#' check_cardinality_0_n(d1, a, d2, c)
#'
#' # This does not pass, injectivity is violated:
#' try(check_cardinality_1_1(d1, a, d2, c))
#'
#' # This passes:
#' check_cardinality_0_1(d1, a, d3, c)
check_cardinality_0_n <- function(parent_table, pk_column, child_table, fk_column) {
  pt <- enquo(parent_table)
  pkc <- ensym(pk_column)
  ct <- enquo(child_table)
  fkc <- ensym(fk_column)

  check_key(!!pt, !!pkc)

  check_if_subset(!!ct, !!fkc, !!pt, !!pkc)

  invisible(TRUE)
}

#' @rdname check_cardinality
#' @export
check_cardinality_1_n <- function(parent_table, pk_column, child_table, fk_column) {
  pt <- enquo(parent_table)
  pkc <- ensym(pk_column)
  ct <- enquo(child_table)
  fkc <- ensym(fk_column)

  check_key(!!pt, !!pkc)

  check_set_equality(!!ct, !!fkc, !!pt, !!pkc)

  invisible(TRUE)
}

#' @rdname check_cardinality
#' @export
check_cardinality_1_1 <- function(parent_table, pk_column, child_table, fk_column) {
  pt <- enquo(parent_table)
  pkc <- ensym(pk_column)
  ct <- enquo(child_table)
  fkc <- ensym(fk_column)

  check_key(!!pt, !!pkc)

  check_set_equality(!!ct, !!fkc, !!pt, !!pkc)

  tryCatch({
    check_key(!!ct, !!fkc)
    NULL
  },
  error = function(e) abort_not_bijective(as_label(ct), as_label(fkc))
  )

  invisible(TRUE)
}

#' @rdname check_cardinality
#' @export
check_cardinality_0_1 <- function(parent_table, pk_column, child_table, fk_column) {
  pt <- enquo(parent_table)
  pkc <- ensym(pk_column)
  ct <- enquo(child_table)
  fkc <- ensym(fk_column)

  check_key(!!pt, !!pkc)

  check_if_subset(!!ct, !!fkc, !!pt, !!pkc)

  tryCatch({
    check_key(!!ct, !!fkc)
    NULL
  },
  error = function(e) abort_not_injective(as_label(ct), as_label(fkc))
  )

  invisible(TRUE)
}
