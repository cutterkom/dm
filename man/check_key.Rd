% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/key-helpers.R
\name{check_key}
\alias{check_key}
\title{Test if column (combination) is unique key of table}
\usage{
check_key(.data, ...)
}
\arguments{
\item{.data}{Data frame whose columns should be tested for key properties.}

\item{...}{Names of columns to be checked. If none specified all columns together are tested for key property.

One or more unquoted expressions separated by commas. You can treat variable names like they are positions, so you
can use expressions like x:y to select ranges of variables.

The arguments in ... are automatically quoted and evaluated in a context where column names represent column positions. They also support
unquoting and splicing. See vignette("programming") for an introduction to these concepts.

See select helpers for more details and examples about tidyselect helpers such as starts_with(), everything(), ...}
}
\description{
\code{check_key()} accepts a data frame and optionally columns and throws an error,
if the given columns (or all columns if none specified) are NOT a unique key of the data frame.
If the columns given in the ellipsis ARE a key, the data frame itself is returned silently for piping convenience.
}
\examples{
data <- tibble::tibble(a = c(1, 2, 1), b = c(1, 4, 1), c = c(5, 6, 7))
# this is failing:
try(check_key(data, a, b))

# this is passing:
check_key(data, a, c)
}
