% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions_feature_plots.R
\name{ssvFeatureEuler}
\alias{ssvFeatureEuler}
\title{Try to load a bed-like file and convert it to a GRanges object}
\usage{
ssvFeatureEuler(object, line_width = 2, shape = c("circle", "ellipse")[1],
  n_points = 200, fill_alpha = 0.3, line_alpha = 1,
  circle_colors = NULL)
}
\arguments{
\item{object}{A membership table}

\item{line_width}{numeric, passed to size aesthetic to control line width}

\item{shape}{shape argument passed to eulerr::euler}

\item{n_points}{number of points to use for drawing ellipses, passed to  eulerr:::ellipse}

\item{fill_alpha}{numeric [0,1], alpha value for circle fill}

\item{line_alpha}{numeric [0,1], alpha value for circle line}

\item{circle_colors}{colors to choose from for circles.  passed to ggplot2 color scales.}
}
\value{
ggplot of venneuler results
}
\description{
Try to load a bed-like file and convert it to a GRanges object
}
\examples{
ssvFeatureEuler(list(1:3, 2:6))
ssvFeatureEuler(CTCF_in_10a_overlaps_gr)
ssvFeatureEuler(S4Vectors::mcols(CTCF_in_10a_overlaps_gr)[,2:3])
}
