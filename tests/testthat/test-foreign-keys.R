context("test-foreign-key-functions")

test_that("cdm_add_fk() works as intended?", {
  iwalk(
    .x = cdm_test_obj_src,
    ~ expect_error(
      cdm_add_fk(.x, cdm_table_1, a, cdm_table_4),
      class = cdm_error("ref_tbl_has_no_pk"),
      error_txt_ref_tbl_has_no_pk("cdm_table_4"),
      fixed = TRUE,
      label = .y
    )
  )

  map(
    .x = cdm_test_obj_src,
    ~ expect_true(
      .x %>%
        cdm_add_pk(cdm_table_4, c) %>%
        cdm_add_fk(cdm_table_1, a, cdm_table_4) %>%
        cdm_has_pk(cdm_table_4)
    )
  )
})

test_that("cdm_has_fk() and cdm_get_fk() work as intended?", {
  map(
    .x = cdm_test_obj_src,
    ~ expect_true(
      .x %>%
        cdm_add_pk(cdm_table_4, c) %>%
        cdm_add_fk(cdm_table_1, a, cdm_table_4) %>%
        cdm_add_fk(cdm_table_2, c, cdm_table_4) %>%
        cdm_has_fk(cdm_table_1, cdm_table_4)
    )
  )

  map(
    .x = cdm_test_obj_src,
    ~ expect_identical(
      .x %>%
        cdm_add_pk(cdm_table_4, c) %>%
        cdm_add_fk(cdm_table_1, a, cdm_table_4) %>%
        cdm_add_fk(cdm_table_2, c, cdm_table_4) %>%
        cdm_get_fk(cdm_table_1, cdm_table_4),
      "a"
    )
  )


  map(
    .x = cdm_test_obj_src,
    ~ expect_true(
      .x %>%
        cdm_add_pk(cdm_table_4, c) %>%
        cdm_add_fk(cdm_table_1, a, cdm_table_4) %>%
        cdm_add_fk(cdm_table_2, c, cdm_table_4) %>%
        cdm_has_fk(cdm_table_2, cdm_table_4)
    )
  )

  map(
    .x = cdm_test_obj_src,
    ~ expect_identical(
      .x %>%
        cdm_add_pk(cdm_table_4, c) %>%
        cdm_add_fk(cdm_table_1, a, cdm_table_4) %>%
        cdm_add_fk(cdm_table_2, c, cdm_table_4) %>%
        cdm_get_fk(cdm_table_2, cdm_table_4),
      "c"
    )
  )

  map(
    .x = cdm_test_obj_src,
    ~ expect_false(
      .x %>%
        cdm_add_pk(cdm_table_4, c) %>%
        cdm_add_fk(cdm_table_1, a, cdm_table_4) %>%
        cdm_add_fk(cdm_table_2, c, cdm_table_4) %>%
        cdm_has_fk(cdm_table_3, cdm_table_4)
    )
  )

  map(
    .x = cdm_test_obj_src,
    ~ expect_identical(
      .x %>%
        cdm_add_pk(cdm_table_4, c) %>%
        cdm_add_fk(cdm_table_1, a, cdm_table_4) %>%
        cdm_add_fk(cdm_table_2, c, cdm_table_4) %>%
        cdm_get_fk(cdm_table_3, cdm_table_4),
      character(0)
    )
  )
})

test_that("cdm_rm_fk() works as intended?", {
  map(
    .x = cdm_test_obj_src,
    function(cdm_test_obj) {
      expect_true(
        cdm_test_obj %>%
          cdm_add_pk(cdm_table_4, c) %>%
          cdm_add_fk(cdm_table_1, a, cdm_table_4) %>%
          cdm_add_fk(cdm_table_2, c, cdm_table_4) %>%
          cdm_rm_fk(cdm_table_2, c, cdm_table_4) %>%
          cdm_has_fk(cdm_table_1, cdm_table_4)
      )
    }
  )

  map(
    .x = cdm_test_obj_src,
    ~ expect_false(
      .x %>%
        cdm_add_pk(cdm_table_4, c) %>%
        cdm_add_fk(cdm_table_1, a, cdm_table_4) %>%
        cdm_add_fk(cdm_table_2, c, cdm_table_4) %>%
        cdm_rm_fk(cdm_table_2, c, cdm_table_4) %>%
        cdm_has_fk(cdm_table_2, cdm_table_4)
    )
  )

  map(
    .x = cdm_test_obj_src,
    ~ expect_false(
      .x %>%
        cdm_add_pk(cdm_table_4, c) %>%
        cdm_add_fk(cdm_table_1, a, cdm_table_4) %>%
        cdm_add_fk(cdm_table_2, c, cdm_table_4) %>%
        cdm_rm_fk(cdm_table_2, NULL, cdm_table_4) %>%
        cdm_has_fk(cdm_table_2, cdm_table_4)
    )
  )

  map(
    .x = cdm_test_obj_src,
    ~ expect_error(
      .x %>%
        cdm_add_pk(cdm_table_4, c) %>%
        cdm_add_fk(cdm_table_1, a, cdm_table_4) %>%
        cdm_add_fk(cdm_table_2, c, cdm_table_4) %>%
        cdm_rm_fk(table = cdm_table_2, ref_table = cdm_table_4),
      class = cdm_error("rm_fk_col_missing")
    )
  )

  map(
    .x = cdm_test_obj_src,
    ~ expect_error(
      .x %>%
        cdm_add_pk(cdm_table_4, c) %>%
        cdm_add_fk(cdm_table_1, a, cdm_table_4) %>%
        cdm_add_fk(cdm_table_2, c, cdm_table_4) %>%
        cdm_rm_fk(cdm_table_2, z, cdm_table_4),
      class = cdm_error("is_not_fkc")
    )
  )
})


test_that("cdm_enum_fk_candidates() works as intended?", {

  # `anti_join()` doesn't distinguish between `dbl` and `int`
  tbl_fk_candidates_t1_t4 <- tribble(
    ~column, ~candidate,  ~why,
    "a",     TRUE,       "",
    "b",     FALSE,      "<reason>"
  )

  map(
    cdm_test_obj_src,
    ~ expect_identical(
      .x %>%
        cdm_add_pk(cdm_table_4, c) %>%
        cdm_enum_fk_candidates(cdm_table_1, cdm_table_4) %>%
        mutate(why = if_else(why != "", "<reason>", "")) %>%
        collect(),
      tbl_fk_candidates_t1_t4
    )
  )

  tbl_t3_t4 <- tibble::tribble(
    ~column, ~candidate,  ~why,
    "c",      FALSE,      "<reason>"
  )

  map(
    cdm_test_obj_2_src,
    ~ expect_equivalent(
      cdm_add_pk(.x, cdm_table_4, c) %>%
        cdm_enum_fk_candidates(cdm_table_3, cdm_table_4) %>%
        mutate(why = if_else(why != "", "<reason>", "")),
      tbl_t3_t4
    )
  )

  tbl_t4_t3 <- tibble::tribble(
    ~column, ~candidate, ~why,
    "c",     TRUE,       ""
  )

  map(
    cdm_test_obj_src,
    ~ expect_identical(
      .x %>%
        cdm_add_pk(cdm_table_3, c) %>%
        cdm_enum_fk_candidates(cdm_table_4, cdm_table_3),
      tbl_t4_t3
    )
  )

  nycflights_example <-     tibble::tribble(
    ~column,          ~candidate, ~why,
    "origin",         TRUE,       "",
    "dest",           FALSE,      "<reason>",
    "tailnum",        FALSE,      "<reason>",
    "carrier",        FALSE,      "<reason>",
    "air_time",       FALSE,      "<reason>",
    "arr_delay",      FALSE,      "<reason>",
    "arr_time",       FALSE,      "<reason>",
    "day",            FALSE,      "<reason>",
    "dep_delay",      FALSE,      "<reason>",
    "dep_time",       FALSE,      "<reason>",
    "distance",       FALSE,      "<reason>",
    "flight",         FALSE,      "<reason>",
    "hour",           FALSE,      "<reason>",
    "minute",         FALSE,      "<reason>",
    "month",          FALSE,      "<reason>",
    "sched_arr_time", FALSE,      "<reason>",
    "sched_dep_time", FALSE,      "<reason>",
    "time_hour",      FALSE,      "<reason>",
    "year",           FALSE,      "<reason>"
  )

  expect_identical(
    cdm_enum_fk_candidates(cdm_nycflights13(), flights, airports) %>%
      mutate(why = if_else(why != "", "<reason>", "")),
    nycflights_example
  )

  map(
    .x = cdm_test_obj_src,
    ~ expect_error(
      cdm_enum_fk_candidates(.x, cdm_table_1, cdm_table_4),
      class = cdm_error("ref_tbl_has_no_pk")
    )
  )
})
