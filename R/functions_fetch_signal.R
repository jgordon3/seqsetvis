# functions useful for fetching signal data regardless of source:
# bam, bigwig, etc.

#' get a windowed sampling of score_gr
#'
#' Summarizes score_gr by grabbing value of "score" every window_size bp.
#' Columns in output data.table are:
#' standard GRanges columns: seqnames, start, end, width, strand
#' id - matched to names(score_gr). if names(score_gr) is missing,
#' added as 1:length(score_gr)
#' y - value of score from score_gr
#' x - relative bp position
#'
#' @param score_gr GRanges with a "score" metadata columns.
#' @param qgr regions to view by window.
#' @param window_size qgr will be represented by value from score_gr every
#' window_size bp.
#' @param x0 character. controls how x value is derived from position for
#' each region in qgr.  0 may be the left side or center.  If not unstranded,
#' x coordinates are flipped for (-) strand.
#' @return data.table that is GRanges compatible
#' @export
#' @examples
#' bam_file = system.file("extdata/test.bam",
#'     package = "seqsetvis")
#' qgr = CTCF_in_10a_overlaps_gr[1:5]
#' qgr = GenomicRanges::resize(qgr, width = 500, fix = "center")
#' bam_gr = fetchBam(bam_file, qgr)
#' bam_dt = viewGRangesWindowed_dt(bam_gr, qgr, 50)
#'
#' if(Sys.info()['sysname'] != "Windows"){
#'     bw_file = system.file("extdata/MCF10A_CTCF_FE_random100.bw",
#'         package = "seqsetvis")
#'     bw_gr = rtracklayer::import.bw(bw_file, which = qgr)
#'     bw_dt = viewGRangesWindowed_dt(bw_gr, qgr, 50)
#' }
viewGRangesWindowed_dt = function(score_gr, qgr, window_size,
                                  x0 = c("center", "center_unstranded",
                                         "left", "left_unstranded")[1]){
    x = id = NULL
    stopifnot(class(score_gr) == "GRanges")
    stopifnot(!is.null(score_gr$score))
    stopifnot(class(qgr) == "GRanges")
    stopifnot(is.numeric(window_size))
    stopifnot(window_size >= 1)
    stopifnot(window_size %% 1 == 0)
    stopifnot(x0 %in% c("center", "center_unstranded", "left", "left_unstranded"))
    windows = slidingWindows(qgr, width = window_size, step = window_size)
    if (is.null(qgr$id)) {
        if (!is.null(names(qgr))) {
            qgr$id = names(qgr)
        } else {
            qgr$id = paste0("region_", seq_along(qgr))
        }
    }
    names(windows) = qgr$id
    windows = unlist(windows)
    windows$id = names(windows)
    windows = resize(windows, width = 1, fix = "center")
    olaps = suppressWarnings(data.table::as.data.table(findOverlaps(query = windows, subject = score_gr)))
    # patch up missing/out of bound data with 0
    missing_idx = setdiff(seq_along(windows), olaps$queryHits)
    if (length(missing_idx) > 0) {
        olaps = rbind(olaps, data.table::data.table(queryHits = missing_idx, subjectHits = length(score_gr) + 1))[order(queryHits)]
        score_gr = c(score_gr, GRanges(seqnames(score_gr)[length(score_gr)], IRanges::IRanges(1, 1), score = 0))
    }
    # set y and output windows = windows[olaps$queryHits]
    windows$y = score_gr[olaps$subjectHits]$score
    score_dt = data.table::as.data.table(windows)

    shift = round(window_size/2)
    switch(x0,
           center = {
               score_dt[, `:=`(x, start - min(start) + shift), by = id]
               score_dt[, `:=`(x, x - round(mean(x))), by = id]
               score_dt[strand == "-", x := -1*x]
           },
           center_unstranded = {
               score_dt[, `:=`(x, start - min(start) + shift), by = id]
               score_dt[, `:=`(x, x - round(mean(x))), by = id]
           },
           left = {
               score_dt[, x := -1]
               score_dt[strand != "-", `:=`(x, start - min(start) + shift), by = id]
               #flip negative
               score_dt[strand == "-", `:=`(x, -1*(end - max(end) - shift)), by = id]
           },
           left_unstranded = {
               score_dt[, `:=`(x, start - min(start) + shift), by = id]
           }
    )

    score_dt[, `:=`(start, start - shift + 1)]
    score_dt[, `:=`(end, end + window_size - shift)]
    if(x0 == "center"){

    }
    score_dt
}

#' prepares GRanges for windowed fetching.
#'
#' output GRanges parallels input with consistent width evenly divisible by
#' win_size.  Has warning if GRanges needed resizing, otherwise no warning
#' and input GRanges is returned unchanged.
#'
#' @param qgr GRanges to prepare
#' @param win_size numeric window size for fetch
#' @param min_quantile numeric [0,1], lowest possible quantile value.  Only
#' relevant if target_size is not specified.
#' @param target_size numeric final width of qgr if known. Default of NULL
#' leads to quantile based determination of target_size.
#' @return GRanges, either identical to qgr or with suitable consistent width
#' applied.
#' @export
#' @examples
#' qgr = prepare_fetch_GRanges(CTCF_in_10a_overlaps_gr, win_size = 50)
#' #no warning if qgr is already valid for windowed fetching
#' prepare_fetch_GRanges(qgr, win_size = 50)
prepare_fetch_GRanges = function(qgr,
                                 win_size,
                                 min_quantile = .75,
                                 target_size = NULL){
    if(length(unique(width(qgr))) > 1 || width(qgr)[1] %% win_size != 0 ){
        if(is.null(target_size)){
            target_size = quantileGRangesWidth(qgr = qgr,
                                               min_quantile = min_quantile,
                                               win_size = win_size)
        }
        if(target_size %% win_size != 0){
            stop("target_size: ", target_size,
                 " not evenly divisible by win_size: ", win_size)
        }

        qgr = centerFixedSizeGRanges(qgr, fixed_size = target_size)
        warning("widths of qgr were not ",
                "identical and evenly divisible by win_size.",
                "\nA fixed width of ",
                target_size, " was applied based on the data provided.")
    }
    return(qgr)
}

#' Quantile width determination strategy
#'
#' Returns the lowest multiple of win_size greater than
#' min_quantile quantile of width(qgr)
#'
#' @param qgr GRanges to calculate quantile width for
#' @param min_quantile numeric [0,1] the minimum quantile of width in qgr
#' @param win_size numeric/integer >=1, returned value will be a multiple of
#' this
#' @return numeric that is >= min_quantile and evenly divisible by win_size
#' @export
#' @examples
#' gr = CTCF_in_10a_overlaps_gr
#' quantileGRangesWidth(gr)
#' quantileGRangesWidth(gr, min_quantile = .5, win_size = 100)
quantileGRangesWidth = function(qgr,
                                min_quantile = .75,
                                win_size = 1){

    stopifnot(class(qgr) == "GRanges")
    stopifnot(is.numeric(min_quantile), is.numeric(win_size))
    stopifnot(min_quantile >= 0 && min_quantile <= 1)
    stopifnot(length(min_quantile) == 1 && length(win_size) == 1)
    stopifnot(win_size%%1==0)
    stopifnot(win_size >= 1)
    qwidth = quantile(width(qgr), min_quantile)
    fwidth = ceiling(qwidth / win_size) * win_size
    return(fwidth)
}

#' Derive a new GRanges of consistent width based on quantile.
#'
#' Width is selected by rounding up to the lowest multiple of win_size greater
#' than min_quantile quantile of widths.
#'
#' @param qgr GRanges. To be resized.
#' @param min_quantile numeric [0,1]. The quantile level final width must be
#' greater than. default is 0.75
#' @param win_size integer > 0.  final width must be a multiple of win_size.
#' @param anchor extend from center of from start (strand sensitive)
#' @return a GRanges derived from qgr (length and order match).  All ranges
#' are of same width and centered on old.  Width is at least minimum quantile
#' and a multiple of win_size
fixGRangesWidth = function(qgr,
                           min_quantile = .75,
                           win_size = 1,
                           anchor = c("center", "start")[1]){
    stopifnot(class(qgr) == "GRanges")
    fwidth = quantileGRangesWidth(qgr, min_quantile, win_size)
    qgr = setGRangesWidth(qgr = qgr, fwidth = fwidth, anchor = anchor)

}

#' Return GRanges with single width
#'
#' Essentially works like GenomicRanges::resize() but repeated applications
#' of center do not cause rounding induced drift.
#' @param qgr GRanges
#' @param fwidth numeric width to apply
#' @param anchor extend from center of from start (strand sensitive)
#' @return GRanges that parallels qgr with fwidth applied according to anchor.
setGRangesWidth = function(qgr, fwidth, anchor = c("center", "start")[1]){
    stopifnot(class(qgr) == "GRanges")
    stopifnot(is.numeric(fwidth))
    stopifnot(anchor %in% c("center", "start"))
    switch(anchor,
           center = {
               centerFixedSizeGRanges(qgr, fixed_size = fwidth)
           },
           start = {
               resize(qgr, width = fwidth, fix = "start")
           }
    )
}


#' Generic signal loading function
#'
#' Does nothing unless load_signal is overridden to carry out reading
#' data from file_paths (likely via the appropriate fetchWindowed function,
#' ie. \code{\link{fetchWindowedBigwig}} or \code{\link{fetchWindowedBam}}
#'
#' @param file_paths character vector of file_paths to load from
#' @param qgr GRanges of intervals to return from each file
#' @param unique_names unique file ids for each file in file_paths.  Default
#' is names of file_paths vector
#' @param names_variable character, variable name for column containing
#' unique_names entries.  Default is "sample"
#' @param win_size numeric/integer window size resolution to load signal at.
#' Default is 50.
#' @param return_data.table logical. If TRUE data.table is returned instead of
#' GRanges, the default.
#' @param load_signal function taking f, nam, and qgr arguments.  f is from
#' file_paths, nam is from unique_names, and qgr is qgr. See details.
#' @details load_signal is passed f, nam, and qgr and is executed in the
#' environment where load_signal is defined. See
#' \code{\link{fetchWindowedBigwig}} and \code{\link{fetchWindowedBam}}
#'  for examples.
#' @return A GRanges with values read from file_paths at intervals of win_size.
#' Originating file is coded by unique_names and assigned to column of name
#' names_variable.  Output is data.table is return_data.table is TRUE.
#' @export
#' @examples
#' library(GenomicRanges)
#' bam_f = system.file("extdata/test.bam",
#'     package = "seqsetvis", mustWork = TRUE)
#' bam_files = c("a" = bam_f, "b" = bam_f)
#' qgr = CTCF_in_10a_overlaps_gr[1:5]
#'
#' load_bam = function(f, nam, qgr) {
#'     message("loading ", f, " ...")
#'     dt = fetchWindowedBam(bam_f = f,
#'                       qgr = qgr,
#'                       win_size = 50,
#'                       fragLen = NULL,
#'                       target_strand = "*",
#'                       return_data.table = TRUE)
#'     dt[["sample"]] = nam
#'     message("finished loading ", nam, ".")
#'     dt
#' }
#' fetchWindowedSignalList(bam_files, qgr, load_signal = load_bam)
fetchWindowedSignalList = function(file_paths,
                                   qgr,
                                   unique_names = names(file_paths),
                                   names_variable = "sample",
                                   win_size = 50,
                                   return_data.table = FALSE,
                                   load_signal = function(f, nam) {
                                       message("loading ", nam, " ...")
                                       warning("nothing happened, add code here to load files")
                                       message("finished loading ", nam, ".")
                                   }){
    if(is.list(file_paths)){
        file_paths = unlist(file_paths)
    }
    if (is.null(unique_names)) {
        unique_names = basename(file_paths)
    }
    names(file_paths) = unique_names
    stopifnot(is.character(file_paths))
    stopifnot(class(qgr) == "GRanges")
    stopifnot(is.character(unique_names))
    stopifnot(is.character(names_variable))
    stopifnot(is.numeric(win_size))
    if (any(duplicated(unique_names))) {
        stop("some unique_names are duplicated:\n",
             paste(collapse = "\n", unique(unique_names[duplicated(unique_names)])))
    }
    qgr = prepare_fetch_GRanges(qgr = qgr, win_size = win_size, target_size = NULL)
    nam_load_signal = function(nam){
        f = file_paths[nam]
        load_signal(f, nam, qgr)
    }
    bw_list = lapply(names(file_paths), nam_load_signal)
    out = data.table::rbindlist(bw_list)
    if(!return_data.table){
        out = GRanges(out)
    }
    return(out)
}
