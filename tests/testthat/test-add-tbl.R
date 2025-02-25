test_that("cdm_add_tbl() works", {

  # is a table added on all sources?
  walk2(
    dm_for_filter_src,
    d1_src,
    ~expect_identical(
      length(cdm_get_tables(cdm_add_tbl(..1, d1 = ..2))),
      7L
    )
  )

  # can I retrieve the tibble under its old name?
  expect_identical(
    tbl(cdm_add_tbl(dm_for_filter, d1), "d1"),
    d1
  )

  # can I retrieve the tibble under a new name?
  expect_identical(
    tbl(cdm_add_tbl(dm_for_filter, test = d1), "test"),
    d1
  )

  # we accept even weird table names, as long as they are unique
  expect_identical(
    tbl(d1 %>% cdm_add_tbl(dm_for_filter, .), "."),
    d1
  )

  # do I avoid the warning when piping the table but setting the name?
  expect_silent(
    expect_identical(
      tbl(d1 %>% cdm_add_tbl(dm_for_filter, new_name = .), "new_name"),
      d1)
  )

  # adding more than 1 table:
  # 1. Is the resulting number of tables correct?
  expect_identical(
    length(cdm_get_tables(cdm_add_tbl(dm_for_filter, d1, d2))),
    8L)

  # 2. Is the resulting order of the tables correct?
  expect_identical(
    src_tbls(cdm_add_tbl(dm_for_filter, d1, d2)),
    c(src_tbls(dm_for_filter), "d1", "d2")
  )

  # Is an error thrown in case I try to give the new table an old table's name?
  expect_error(
    cdm_add_tbl(dm_for_filter, t1 = d1),
    class = "vctrs_error_names_must_be_unique"
  )

  expect_message(
    expect_equivalent_dm(
      cdm_add_tbl(dm_for_filter, t1 = d1, repair = "unique"),
      dm_for_filter %>%
        cdm_rename_tbl(t1...1 = t1) %>%
        cdm_add_tbl(t1...7 = d1)
    )
  )

  # error in case table srcs don't match
  if (length(test_srcs) > 1) {
    d1_db <- d1_src[-1]
    walk(
      d1_db,
      ~expect_error(
        cdm_add_tbl(dm_for_filter, .),
        class = cdm_error("not_same_src")
      )
    )
  }
})

test_that("cdm_rm_tbl() works", {
  # removes a table on all srcs
  map(
    dm_for_filter_w_cycle_src,
    ~expect_equivalent_dm(
      cdm_rm_tbl(., t7) %>% collect(),
      dm_for_filter
      )
  )

  # removes more than one table
  expect_equivalent_dm(
    cdm_rm_tbl(dm_for_filter_w_cycle, t7, t5, t3) %>% collect(),
    cdm_select_tbl(dm_for_filter, t1, t2, t4, t6)
  )

  # fails when table name is wrong
  expect_error(
    cdm_rm_tbl(dm_for_filter, t7),
    class = cdm_error("table_not_in_dm")
  )
})
