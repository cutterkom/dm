% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nycflights13.R
\name{cdm_nycflights13}
\alias{cdm_nycflights13}
\title{Creates a \code{\link{dm}} object for the \pkg{nycflights13} data}
\usage{
cdm_nycflights13(cycle = FALSE, color = TRUE)
}
\arguments{
\item{cycle}{Boolean. If \code{FALSE} (default), only one foreign key relation
(from \code{flights$origin} to \code{airports$faa}) between \code{flights} and \code{airports} is
established. If \code{TRUE}, a \code{dm} object with a double reference
between those tables will be produced.}

\item{color}{Boolean, if \code{TRUE} (default), the resulting \code{dm} object will have
colors assigned to different tables for visualization with \code{cdm_draw()}}
}
\description{
Creates an exemplary \code{\link{dm}} object from the tables in \pkg{nycflights13}
along with the references.
See \link[nycflights13:flights]{nycflights13::flights} for a description of the data.
As described in \link[nycflights13:planes]{nycflights13::planes}, the relationship
between the \code{flights} and \code{planes} tables is "weak", it does not satisfy
data integrity constraints.
}
\examples{
if (rlang::is_installed("nycflights13")) {
  cdm_nycflights13() \%>\%
    cdm_draw()
}
}
