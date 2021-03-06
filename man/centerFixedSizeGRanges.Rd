% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions_signal_operations.R
\name{centerFixedSizeGRanges}
\alias{centerFixedSizeGRanges}
\title{Transforms set of GRanges to all have the same size.}
\usage{
centerFixedSizeGRanges(grs, fixed_size = 2000)
}
\arguments{
\item{grs}{Set of GRanges with incosistent and/or incorrect size}

\item{fixed_size}{The final width of each GRange returned.}
}
\value{
Set of GRanges after resizing all input GRanges, either shortened
or lengthened as required to match \code{fixed_size}
}
\description{
\code{centerFixedSizeGRanges} First calculates the central coordinate of each
GRange in \code{grs} and extends in both direction by half of \code{fixed_size}
}
\examples{
library(GenomicRanges)
grs = GRanges("chr1", IRanges(1:10+100, 1:10*3+100))
centered_grs = centerFixedSizeGRanges(grs, 10)
width(centered_grs)
}
