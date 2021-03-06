% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions_fetch_bam.R
\name{fragLen_calcStranded}
\alias{fragLen_calcStranded}
\title{calculate fragLen from a bam file for specified regions}
\usage{
fragLen_calcStranded(bam_f, qgr, ma_distance = 21, n_regions = 100,
  force_no_which = FALSE, include_plot_in_output = FALSE,
  max_fragLen = 300, ...)
}
\arguments{
\item{bam_f}{character or BamFile. bam file to read from.
.bai index file must be in same directory}

\item{qgr}{GRanges.  used as which for ScanBamParam. Can be NULL if it's
REALLY important to load the entire bam, force_no_which = TRUE also required.}

\item{ma_distance}{numeric (integer)  range to use for movingRange.
Default is 21.}

\item{n_regions}{numeric (integer) it's generally overkill to pull all
regions at this stage and will slow calculation down.  Default is 100.}

\item{force_no_which}{logical. if TRUE and qgr is also NULL, the entire
bam will be read.}

\item{include_plot_in_output}{if TRUE ouptut is a list of fragLen and a
ggplot showing values considered by calculation. Default is FALSE.}

\item{max_fragLen}{numeric.  The maximum fragLen to calculate for. Calculation
time is directly proportional to this number. Default
is 300.}

\item{...}{passed to Rsamtools::ScanBamParam, can't be which or what.}
}
\value{
numeric fragment length
}
\description{
calculate fragLen from a bam file for specified regions
}
\examples{
bam_file = system.file("extdata/test.bam",
    package = "seqsetvis")
qgr = CTCF_in_10a_overlaps_gr[1:5]
fragLen_calcStranded(bam_file, qgr)
#if plot is included, a list is returned, item 2 is the plot
fragLen_calcStranded(bam_file, qgr,
  include_plot_in_output = TRUE)[[2]]
}
