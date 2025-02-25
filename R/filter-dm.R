#' Filtering a [`dm`] object
#'
#' Filtering one table of a [`dm`] object has an effect on all tables connected to this table
#' via one or more steps of foreign key relations. Firstly, one or more filter conditions for
#' one or more tables can be defined using `cdm_filter()`, with a syntax similar to `dplyr::filter()`.
#' These conditions will be stored in the [`dm`] and not immediately executed. With `cdm_apply_filters()`
#' all tables will be updated according to the filter conditions and the foreign key relations.
#'
#'
#' @details `cdm_filter()` allows you to set one or more filter conditions for one table
#' of a [`dm`] object. These conditions will be stored in the [`dm`] for when they are needed.
#' Once executed, the filtering the will affect all tables connected to the filtered one by
#' foreign key constraints, leaving only the rows with the corresponding key values. The filtering
#' implicitly takes place, once a table is requested from the [`dm`] by using one of `tbl()`, `[[.dm()`, `$.dm()`.
#'
#' @rdname cdm_filter
#'
#' @inheritParams cdm_add_pk
#' @param ... Logical predicates defined in terms of the variables in `.data`, passed on to [dplyr::filter()].
#' Multiple conditions are combined with `&` or `,`. Only rows where the condition evaluates
#' to TRUE are kept.
#'
#' The arguments in ... are automatically quoted and evaluated in the context of
#' the data frame. They support unquoting and splicing. See `vignette("programming", package = "dplyr")`
#' for an introduction to these concepts.
#'
#' @examples
#' library(dplyr)
#'
#' dm_nyc_filtered <-
#'   cdm_nycflights13() %>%
#'   cdm_filter(airports, name == "John F Kennedy Intl")
#'
#' tbl(dm_nyc_filtered, "flights")
#' dm_nyc_filtered[["planes"]]
#' dm_nyc_filtered$airlines
#'
#' cdm_nycflights13() %>%
#'   cdm_filter(airports, name == "John F Kennedy Intl") %>%
#'   cdm_apply_filters()
#' @export
cdm_filter <- function(dm, table, ...) {
  table <- as_name(ensym(table))
  check_correct_input(dm, table)

  quos <- enquos(...)
  if (is_empty(quos)) {
    return(dm)
  } # valid table and empty ellipsis provided

  set_filter_for_table(dm, table, quos)
}

set_filter_for_table <- function(dm, table, quos) {
  def <- cdm_get_def(dm)

  i <- which(def$table == table)
  def$filters[[i]] <- vctrs::vec_rbind(def$filters[[i]], new_filter(quos))
  new_dm3(def)
}

#' @details With `cdm_apply_filters()` all set filter conditions are applied and their
#' combined cascading effect on each table of the [`dm`] is taken into account, producing a new
#' `dm` object.
#' This function is called by the `compute()` method for `dm` class objects.
#'
#' @rdname cdm_filter
#'
#' @inheritParams cdm_add_pk
#'
#' @examples
#' cdm_nycflights13() %>%
#'   cdm_filter(flights, month == 3) %>%
#'   cdm_apply_filters()
#'
#' library(dplyr)
#' cdm_nycflights13() %>%
#'   cdm_filter(planes, engine %in% c("Reciprocating", "4 Cycle")) %>%
#'   compute()
#' @export
cdm_apply_filters <- function(dm) {
  def <- cdm_get_def(dm)

  def$data <- map(def$table, ~ tbl(dm, .))

  cdm_reset_all_filters(new_dm3(def))
}


cdm_get_filtered_table <- function(dm, from) {
  filters <- cdm_get_filter(dm)
  if (nrow(filters) == 0) {
    return(cdm_get_tables(dm)[[from]])
  }

  fc <- get_all_filtered_connected(dm, from)

  f_quos <- filters %>%
    nest(filter = -table)

  fc_children <-
    fc %>%
    filter(node != parent) %>%
    select(-distance) %>%
    nest(semi_join = -parent) %>%
    rename(table = parent)

  recipe <-
    fc %>%
    select(table = node) %>%
    left_join(fc_children, by = "table") %>%
    left_join(f_quos, by = "table")

  list_of_tables <- cdm_get_tables(dm)

  for (i in seq_len(nrow(recipe))) {
    table_name <- recipe$table[i]
    table <- list_of_tables[[table_name]]

    semi_joins <- recipe$semi_join[[i]]
    if (!is_null(semi_joins)) {
      semi_joins <- pull(semi_joins)
      semi_joins_tbls <- list_of_tables[semi_joins]
      table <-
        reduce2(semi_joins_tbls,
          semi_joins,
          ~ semi_join(..1, ..2, by = get_by(dm, table_name, ..3)),
          .init = table
        )
    }

    filter_quos <- recipe$filter[[i]]
    if (!is_null(filter_quos)) {
      filter_quos <- pull(filter_quos)
      table <- filter(table, !!!filter_quos)
    }

    list_of_tables[[table_name]] <- table
  }
  list_of_tables[[from]]
}

get_all_filtered_connected <- function(dm, table) {
  filtered_tables <- unique(cdm_get_filter(dm)$table)
  graph <- create_graph_from_dm(dm)

  # Computation of distances and shortest paths uses the same algorithm
  # internally, but s.p. doesn't return distances and distances don't return
  # the predecessor.
  distances <- igraph::distances(graph, table)[1, ]
  finite_distances <- distances[is.finite(distances)]

  # Using only nodes with finite distances (=in the same connected component)
  # as target. This avoids a warning.
  target_tables <- names(finite_distances)
  paths <- igraph::shortest_paths(graph, table, target_tables, predecessors = TRUE)

  # All edges with finite distance as tidy data frame
  all_edges <-
    tibble(
      node = names(V(graph)),
      parent = names(paths$predecessors),
      distance = distances
    ) %>%
    filter(is.finite(distance))

  # Edges of interest, will be grown until source node `table` is reachable
  # from all nodes
  edges <-
    all_edges %>%
    filter(node %in% !!c(filtered_tables, table))

  # Recursive join
  repeat {
    missing <- setdiff(edges$parent, edges$node)
    if (is_empty(missing)) break

    edges <- bind_rows(edges, filter(all_edges, node %in% !!missing))
  }

  # Keeping the sentinel row (node == parent) to simplify further processing
  # and testing
  edges %>%
    arrange(-distance)
}

check_no_filter <- function(dm) {
  def <-
    cdm_get_def(dm)

  if (detect_index(def$filters, ~ vctrs::vec_size(.) > 0) == 0) return()

  fun_name <- as_string(sys.call(-1)[[1]])
  abort_only_possible_wo_filters(fun_name)
}
