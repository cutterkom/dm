% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/flatten.R
\name{cdm_join_to_tbl}
\alias{cdm_join_to_tbl}
\title{Perform a join between two tables of a \code{\link{dm}}}
\usage{
cdm_join_to_tbl(dm, table_1, table_2, join = left_join)
}
\arguments{
\item{dm}{A \code{\link{dm}} object}

\item{table_1}{One of the tables involved in the join}

\item{table_2}{The second table of the join}

\item{join}{The type of join to be performed, see \code{\link[dplyr:join]{dplyr::join()}}}
}
\value{
The resulting table of the join.
}
\description{
A join of desired type is performed between table \code{table_1} and
table \code{table_2}. The two tables need to be directly connected by a foreign key
relation. Since this function is a wrapper around \code{\link[=cdm_flatten_to_tbl]{cdm_flatten_to_tbl()}}, the LHS of
the join will always be the "child table", the table referencing the other table.
}
\seealso{
Other flattening functions: \code{\link{cdm_flatten_to_tbl}}
}
\concept{flattening functions}
