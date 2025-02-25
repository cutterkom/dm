#' Validate your [`dm`]: are all key constraints met?
#'
#' This function returns a tibble with information, which key constraints are met (`is_key = TRUE`) or violated (`FALSE`).
#'
#' @inheritParams cdm_add_pk
#'
#' @return A tibble with 5 columns:
#'   1. `table`: the table in the `dm`
#'   1. `kind`: "PK" or "FK"
#'   1. `column`: column of `table`
#'   1. `is_key`: logical
#'   1. `problem`: in case `is_key = FALSE` the reason for that
#'
#' @details For the primary key constraints it is tested, if the values in the respective columns are all unique.
#' For the foreign key constraints the tests check, if for each foreign key constraint, the values of the foreign key column
#' are a subset of those of the referenced column.
#'
#' @export
#' @examples
#' cdm_check_constraints(cdm_nycflights13())
cdm_check_constraints <- function(dm) {
  pk_results <- check_pk_constraints(dm)
  fk_results <- check_fk_constraints(dm)
  bind_rows(
    pk_results,
    fk_results
  ) %>%
    arrange(is_key, desc(kind), table, column)
}


#' Test if column (combination) is unique key of table
#'
#' @description `check_key()` accepts a data frame and optionally columns and throws an error,
#' if the given columns (or all columns if none specified) are NOT a unique key of the data frame.
#' If the columns given in the ellipsis ARE a key, the data frame itself is returned silently for piping convenience.
#'
#' @param .data Data frame whose columns should be tested for key properties.
#' @param ... Names of columns to be checked. If none specified all columns together are tested for key property.
#'
#' One or more unquoted expressions separated by commas. You can treat variable names like they are positions, so you
#' can use expressions like x:y to select ranges of variables.
#'
#' The arguments in ... are automatically quoted and evaluated in a context where column names represent column positions. They also support
#' unquoting and splicing. See vignette("programming") for an introduction to these concepts.
#'
#' See select helpers for more details and examples about tidyselect helpers such as starts_with(), everything(), ...
#'
#' @export
#' @examples
#' data <- tibble::tibble(a = c(1, 2, 1), b = c(1, 4, 1), c = c(5, 6, 7))
#' # this is failing:
#' try(check_key(data, a, b))
#'
#' # this is passing:
#' check_key(data, a, c)
check_key <- function(.data, ...) {
  data_q <- enquo(.data)
  .data <- eval_tidy(data_q)
  args <- exprs(...)
  names(args) <- set_names(paste0("...", seq_along(args)))

  duplicate_rows <-
    .data %>%
    as_tibble() %>% # as_tibble works only, if as_tibble.sf()-method is available
    count(!!!args) %>%
    filter(n != 1)

  if (nrow(duplicate_rows) != 0) abort_not_unique_key(as_label(data_q), map_chr(args, as_label))

  invisible(.data)
}

# internal function to check if a column is a unique key of a table
is_unique_key <- nse_function(c(.data, column), ~ {
  col_expr <- ensym(column)
  col_name <- as_name(col_expr)

  duplicate_rows <-
    .data %>%
    count(value = !!col_expr) %>%
    filter(n != 1) %>%
    arrange(value) %>%
    utils::head(MAX_COMMAS + 1) %>%
    collect() %>%
    {
      # https://github.com/tidyverse/tidyr/issues/734
      tibble(data = list(.))
    } %>%
    mutate(unique = map_lgl(data, ~ nrow(.) == 0))

  duplicate_rows
})

#' Test if the value sets of two different columns in two different tables are the same
#'
#' @description `check_set_equality()` is a wrapper of `check_if_subset()`. It tests if
#' one value set is a subset of another and vice versa, i.e., if both sets are the same.
#' If not, it throws an error.
#'
#' @param t1 Data frame containing the column `c1`.
#' @param c1 Column of `t1` that should only contain values that are also in `c2` of data frame `t2`.
#' @param t2 Data frame containing the column `c2`.
#' @param c2 Column of `t2` that should only contain values that are also in `c1` of data frame `t1`.
#'
#' @export
#' @examples
#' data_1 <- tibble::tibble(a = c(1, 2, 1), b = c(1, 4, 1), c = c(5, 6, 7))
#' data_2 <- tibble::tibble(a = c(1, 2, 3), b = c(4, 5, 6), c = c(7, 8, 9))
#' # this is failing:
#' try(check_set_equality(data_1, a, data_2, a))
#'
#' data_3 <- tibble::tibble(a = c(2, 1, 2), b = c(4, 5, 6), c = c(7, 8, 9))
#' # this is passing:
#' check_set_equality(data_1, a, data_3, a)
check_set_equality <- function(t1, c1, t2, c2) {
  t1q <- enquo(t1)
  t2q <- enquo(t2)

  c1q <- ensym(c1)
  c2q <- ensym(c2)

  catcher_1 <- tryCatch({
    check_if_subset(!!t1q, !!c1q, !!t2q, !!c2q)
    NULL
  },
  error = identity
  )

  catcher_2 <- tryCatch({
    check_if_subset(!!t2q, !!c2q, !!t1q, !!c1q)
    NULL
  },
  error = identity
  )

  catchers <- compact(list(catcher_1, catcher_2))

  if (length(catchers) > 0) {
    abort_sets_not_equal(map_chr(catchers, conditionMessage))
  }

  invisible(eval_tidy(t1q))
}

#' Test if values of one column are a subset of values of another column
#'
#' @description `check_if_subset()` tests, if the values of the chosen column `c1` of data frame `t1` are a subset of the values
#' of column `c2` of data frame `t2`.
#'
#' @param t1 Data frame containing the column `c1`.
#' @param c1 Column of `t1` that should only contain values that are also in `c2` of data frame `t2`.
#' @param t2 Data frame containing the column `c2`.
#' @param c2 Column of second data frame which has to contain all values of `c1` to avoid an error.
#'
#' @export
#' @examples
#' data_1 <- tibble::tibble(a = c(1, 2, 1), b = c(1, 4, 1), c = c(5, 6, 7))
#' data_2 <- tibble::tibble(a = c(1, 2, 3), b = c(4, 5, 6), c = c(7, 8, 9))
#' # this is passing:
#' check_if_subset(data_1, a, data_2, a)
#'
#' # this is failing:
#' try(check_if_subset(data_2, a, data_1, a))
check_if_subset <- function(t1, c1, t2, c2) {
  t1q <- enquo(t1)
  t2q <- enquo(t2)

  c1q <- ensym(c1)
  c2q <- ensym(c2)

  if (is_subset(eval_tidy(t1q), !!c1q, eval_tidy(t2q), !!c2q)) {
    return(invisible(eval_tidy(t1q)))
  }

  # Hier kann nicht t1 direkt verwendet werden, da das für den Aufruf
  # check_if_subset(!!t1q, !!c1q, !!t2q, !!c2q) der Auswertung des Ausdrucks !!t1q
  # entsprechen würde; dies ist nicht erlaubt.
  # Siehe eval-bang.R für ein Minimalbeispiel.
  v1 <- pull(eval_tidy(t1q), !!ensym(c1q))
  v2 <- pull(eval_tidy(t2q), !!ensym(c2q))

  setdiff_v1_v2 <- setdiff(v1, v2)
  print(filter(eval_tidy(t1q), !!c1q %in% setdiff_v1_v2))
  abort_not_subset_of(as_name(t1q), as_name(c1q), as_name(t2q), as_name(c2q))
}

# similar to `check_if_subset()`, but evaluates to a boolean
is_subset <- function(t1, c1, t2, c2) {
  t1q <- enquo(t1)
  t2q <- enquo(t2)

  c1q <- ensym(c1)
  c2q <- ensym(c2)

  # Hier kann nicht t1 direkt verwendet werden, da das für den Aufruf
  # check_if_subset(!!t1q, !!c1q, !!t2q, !!c2q) der Auswertung des Ausdrucks !!t1q
  # entsprechen würde; dies ist nicht erlaubt.
  # Siehe eval-bang.R für ein Minimalbeispiel.
  v1 <- pull(eval_tidy(t1q), !!ensym(c1q))
  v2 <- pull(eval_tidy(t2q), !!ensym(c2q))

  if (!all(v1 %in% v2)) FALSE else TRUE
}

check_pk_constraints <- function(dm) {
  pks <- cdm_get_all_pks(dm)
  if (nrow(pks) == 0) return(tibble(
    table = character(0),
    kind = character(0),
    column = character(0),
    is_key = logical(0),
    problem = character(0)
    )
  )
  table_names <- pull(pks, table)
  tbls <- map(set_names(table_names), ~ tbl(dm, .)) %>%
    map2(syms(pks$pk_col), ~select(.x, !!.y))
  tbl_is_pk <- map_dfr(tbls, enum_pk_candidates) %>%
    rename(is_key = candidate, problem = why)

  tibble(
    table = table_names,
    kind = "PK",
    column = pks$pk_col
  ) %>%
    left_join(tbl_is_pk, by = "column")
}

check_fk_constraints <- function(dm) {
  fks <-  left_join(cdm_get_all_fks(dm), cdm_get_all_pks(dm), by = c("parent_table" = "table"))
  pts <- pull(fks, parent_table) %>% map(tbl, src = dm)
  cts <- pull(fks, child_table) %>% map(tbl, src = dm)
  fks_tibble <- mutate(fks, t1 = cts, t2 = pts) %>%
    select(t1, t1_name = child_table, colname = child_fk_col, t2, t2_name = parent_table, pk = pk_col)
  mutate(
    fks_tibble, problem = pmap_chr(fks_tibble, check_fk),
    is_key = if_else(problem == "", TRUE, FALSE),
    kind = "FK"
  ) %>%
    select(table = t1_name, kind, column = colname, is_key, problem)
}
