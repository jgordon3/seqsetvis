% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions_feature_plots.R
\name{ssvFeaturePie}
\alias{ssvFeaturePie}
\title{pie plot of set sizes}
\usage{
ssvFeaturePie(object)
}
\arguments{
\item{object}{object that ssvMakeMembTable can convert to logical matrix membership}
}
\value{
ggplot pie graph of set sizes
}
\description{
pie plot of set sizes
}
\examples{
ssvFeaturePie(list(1:3, 2:6))
ssvFeaturePie(CTCF_in_10a_overlaps_gr)
ssvFeaturePie(S4Vectors::mcols(CTCF_in_10a_overlaps_gr)[,2:3])
}
