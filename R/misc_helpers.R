#' converts a valid r color name ("black", "red", "white", etc.) to a hex value
#' @export
#' @param color_name character. one or more r color names.
#' @importFrom grDevices col2rgb rgb
#' @return hex value of colors coded by colors()
#' @examples
#' col2hex(c("red", "green", "blue"))
#' col2hex(c("lightgray", "gray", "darkgray"))
col2hex = function(color_name) {
    stopifnot(is.character(color_name))
    grDevices::rgb(t(grDevices::col2rgb(color_name))/255)
}

#' convert a list of sets, each list item should be a character vector
#' denoting items in sets
#' @param set_list a list of character vectors.  default names will be added if
#' missing
#' @return converts list of characters/numeric to membership table matrix
set_list2memb = function(set_list) {
    stopifnot(is.list(set_list))
    if (is.null(names(set_list))) {
        names(set_list) = paste0("set_", LETTERS[seq_along(set_list)])
    }
    rn = unique(unlist(set_list))
    cn = names(set_list)
    memb = matrix(FALSE, nrow = length(rn), ncol = length(cn))
    rownames(memb) = rn
    colnames(memb) = cn
    for (column in cn) {
        memb[set_list[[column]], column] = TRUE
    }
    return(memb)
}

#' allows RColorBrew to handle n values less than 3 and greater than 8 without
#' warnings and return expected number of colors.
#' @export
#' @param n integer value of number of colors to make palette for
#' @param pal palette recognized by RColorBrewer
#' @importFrom RColorBrewer brewer.pal brewer.pal.info
#' @return a character vector of hex coded colors o flength n from the color
#' brewer palette pal
#' @examples
#' plot(1:2, rep(0, 2),  col = safeBrew(2, "dark2"), pch = 16, cex = 6)
#' plot(1:12, rep(0, 12),  col = safeBrew(12, "set1"), pch = 16, cex = 6)
#' plot(1:12, rep(0, 12),  col = safeBrew(12, "set2"), pch = 16, cex = 6)
#' plot(1:12, rep(0, 12),  col = safeBrew(12, "set3"), pch = 16, cex = 6)
safeBrew = function(n, pal = "Dark2"){
    stopifnot(is.numeric(n))
    stopifnot(is.character(pal))
    if(n < 1) stop("n must be at least 1")
    pal_info = RColorBrewer::brewer.pal.info
    pal_info$brewName = rownames(pal_info)
    rownames(pal_info) = tolower(rownames(pal_info))
    pal = tolower(pal)
    if(!any(pal == rownames(pal_info)))
        stop("Palette", pal, "not a valid RColorBrewer palette, see RColorBrewer::brewer.pal.info")
    maxColors = pal_info[pal,]$maxcolors
    nbrew = min(max(n, 3), maxColors)
    RColorBrewer::brewer.pal(n = nbrew, name = pal_info[pal,]$brewName)[(seq_len(n)-1) %% maxColors + 1]
}

# x: the vector n: the number of samples centered: if FALSE, then average current sample and previous (n-1) samples if TRUE, then average symmetrically in past and
# future. (If n is even, use one more sample from future.)
# from http://www.cookbook-r.com/Manipulating_data/Calculating_a_moving_average/
movingAverage <- function(x, n = 1, centered = TRUE) {

    if (centered) {
        before <- floor((n - 1)/2)
        after <- ceiling((n - 1)/2)
    } else {
        before <- n - 1
        after <- 0
    }

    # Track the sum and count of number of non-NA items
    s <- rep(0, length(x))
    count <- rep(0, length(x))

    # Add the centered data
    new <- x
    # Add to count list wherever there isn't a
    count <- count + (!is.na(new))
    # Now replace NA_s with 0_s and add to total
    new[is.na(new)] <- 0
    s <- s + new

    # Add the data from before
    i <- 1
    while (i <= before) {
        # This is the vector with offset values to add
        new <- c(rep(NA, i), x[seq_len(length(x) - i)])

        count <- count + (!is.na(new))
        new[is.na(new)] <- 0
        s <- s + new

        i <- i + 1
    }

    # Add the data from after
    i <- 1
    while (i <= after) {
        # This is the vector with offset values to add
        new <- c(x[(i + 1):length(x)], rep(NA, i))

        count <- count + (!is.na(new))
        new[is.na(new)] <- 0
        s <- s + new

        i <- i + 1
    }

    # return sum divided by count
    s/count
}

#' returns a ggplot with ellipses drawn using specified parameters
#' used by ssvFeatureVenn and ssvFeatureEuler
#'
#' @param xcentres numeric x-coord of centers of ellipses
#' @param ycentres numeric y-coord of centers of ellipses, must have same
#' length as xcentres
#' @param r numeric radius1 of ellipse, must have length of 1 or match length
#' of xcentres
#' @param r2 numeric radius2 of ellipse, must have length of 1 or match length
#' of xcentres.  same as r by default.
#' @param phi numeric phi of ellipse, must have length of 1 or match length
#' of xcentres.  0 by default.
#' @param circle_colors character of rcolors or hex colors or NULL.  if
#' null safeBrew of Dark2 is used
#' @param group_names character/factor names of color/fill groups.  capital
#' letters by default.
#' @param line_alpha numeric [0,1] alpha of lines, 1 by default
#' @param fill_alpha numeric [0,1] alpha of fill, .3 by default.
#' @param line_width numeric > 0.  passed to size. 2 by default
#' @param n_points integer > 1.  number of points to approximate circle with.
#' 200 by default
#' @return a ggplot containing ellipses
#' @export
#' @examples
#' ggellipse(xcentres = c(1, 1, 2),
#'     ycentres = c(2, 1, 1),
#'     r = c(1, 2, 1))
#' ggellipse(xcentres = c(1, 1, 2),
#'     ycentres = c(2, 1, 1),
#'     r = c(1, 2, 1),
#'     fill_alpha = 0,
#'     group_names = paste("set", 1:3))
#'ggellipse(xcentres = c(1, 1, 2),
#'     ycentres = c(2, 1, 1),
#'     r = c(1, 2, 1),
#'     circle_colors = c("red", "orange", "yellow"),
#'     line_alpha = 0,
#'     group_names = paste("set", 1:3))
ggellipse = function(xcentres,
                     ycentres,
                     r,
                     r2 = r,
                     phi = rep(0, length(xcentres)),
                     circle_colors = NULL,
                     group_names = LETTERS[seq_along(xcentres)],
                     line_alpha = 1,
                     fill_alpha = .3,
                     line_width = 2,
                     n_points = 200){
    stopifnot(length(xcentres) == length(ycentres))
    n_circles = length(xcentres)
    stopifnot(is.numeric(xcentres), is.numeric(ycentres),
              is.numeric(r), is.numeric(phi))
    stopifnot(length(r) == 1 || length(r) == n_circles)
    if(length(r) == 1) r = rep(r, n_circles)
    stopifnot(length(r2) == 1 || length(r2) == n_circles)
    if(length(r2) == 1) r2 = rep(r2, n_circles)
    stopifnot(length(phi) == 1 || length(phi) == n_circles)
    if(length(phi) == 1) phi = rep(phi, n_circles)
    stopifnot(all(is.character(group_names) | is.factor(group_names)))
    stopifnot(length(group_names) == n_circles)
    stopifnot(is.numeric(line_alpha), is.numeric(fill_alpha),
              is.numeric(line_width))

    #ellipse coordinates
    # internal function from eulerr
    eulerr_ellipse = function (h, k, a, b = a, phi = 0, n = 200L) {
        theta <- seq.int(0, 2 * pi, length.out = n)
        m <- length(h)
        out <- vector("list", m)
        for (i in seq_along(h)) {
            out[[i]]$x <- h[i] + a[i] * cos(theta) * cos(phi[i]) -
                b[i] * sin(theta) * sin(phi[i])
            out[[i]]$y <- k[i] + b[i] * sin(theta) * cos(phi[i]) +
                a[i] * cos(theta) * sin(phi[i])
        }
        out
    }

    e <- eulerr_ellipse(xcentres, ycentres, r,
                        r2, phi, n_points)
    names(e) = group_names
    x = y = group = NULL #reserve data.table bindings
    ell_dt = lapply(e, function(ell)data.table::data.table(x = ell$x, y = ell$y))
    ell_dt = data.table::rbindlist(ell_dt, use.names = TRUE, idcol = "group")
    #check colors
    stopifnot(is.null(circle_colors) || all(is.character(circle_colors)))

    if (is.null(circle_colors)) {
        circle_colors = safeBrew(n_circles, "Dark2")
    } else {
        not_hex = substr(circle_colors, 0, 1) != "#"
        circle_colors[not_hex] = col2hex(circle_colors[not_hex])
    }
    stopifnot(length(circle_colors) == 1 || length(circle_colors) == n_circles)
    if (length(circle_colors) < n_circles)
        circle_colors <- rep(circle_colors, length.out = n_circles)

    if(length(circle_colors) == 1) circle_colors = rep(circle_colors, n_circles)
    # make scales
    names(circle_colors) = group_names

    ahex = substr(grDevices::rgb(red = 1, blue = 1, green = 1, alpha = fill_alpha), start = 8, stop = 9)
    fill_scale = paste0(circle_colors, ahex)
    names(fill_scale) = names(circle_colors)

    ahex = substr(grDevices::rgb(red = 1, blue = 1, green = 1, alpha = line_alpha), start = 8, stop = 9)
    line_scale = paste0(circle_colors, ahex)
    names(line_scale) = names(circle_colors)

    # make plot
    p = ggplot() +
        labs(fill = "", color = "") +
        scale_color_manual(values = line_scale) +
        scale_size_identity() +
        scale_fill_manual(values = fill_scale) +
        theme_minimal() +
        theme(plot.background = element_blank(),
              axis.title = element_blank(),
              axis.text = element_blank(),
              axis.ticks = element_blank(),
              panel.grid = element_blank(),
              legend.position = "top") +
        coord_fixed()
    p = p +
        geom_polygon(data = ell_dt, aes(x = x,
                                        y = y,
                                        fill = group,
                                        col = NA,
                                        alpha = fill_alpha
        )) +
        geom_polygon(data = ell_dt, aes(x = x,
                                        y = y,
                                        fill = NA,
                                        col = group,
                                        size = line_width
        )) +
        scale_alpha_identity() + guides(alpha = "none")
    p
}

