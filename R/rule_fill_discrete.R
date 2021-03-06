#' Fill column with discrete colors
#'
#' Fills a column or columns of a data frame using a discrete
#' colour palette, based on an expression.
#'
#' @family rule
#' @param ... Comma separated list of unquoted column names.
#'            If \code{expression} is also given, then this list can use any of the
#'            \code{\link[dplyr]{select}} syntax possibilities.
#' @param expression an expression to be evaluated with the data.
#'                   It should evaluate to a logical or an integer vector,
#'                   that will be used to determine which cells are to be coloured.
#' @param colours a character vector with colours as values and the expression
#'                possible results as names.
#' @inheritParams scales::hue_pal
#' @param na.value a character string with the CSS color to be used in missing values
#' @param lockcells logical value determining if no further rules should be applied to the affected cells.
#'
#' @return The condformat_tbl object, with the added formatting information
#' @examples
#' data(iris)
#' condformat(iris[c(1:5, 70:75, 120:125), ]) +
#'  rule_fill_discrete(Species, colours = c("setosa" = "red",
#'                                          "versicolor" = "blue",
#'                                          "virginica" = "green")) +
#'  rule_fill_discrete(Sepal.Length, expression=Sepal.Length > 4.6,
#'                     colours=c("TRUE"="red"))
#' @export
rule_fill_discrete <- function(...,
                               expression,
                               colours = NA,
                               na.value = "#FFFFFF",
                               h = c(0, 360) + 15, c = 100, l = 65,
                               h.start = 0, direction = 1,
                               lockcells=FALSE) {
  columns <- lazyeval::lazy_dots(...)
  if (missing(expression)) {
    if (length(columns) > 1) {
      warning("rule_fill_discrete applied to multiple variables, using the first given variable as expression")
    }
    expression <- columns[[1]]
  } else {
    expression <- lazyeval::lazy(expression)
  }

  rule <- structure(list(columns = columns,
                         expression = expression,
                         colours = force(colours),
                         h = force(h),
                         c = force(c), l = force(l),
                         h.start = force(h.start),
                         direction = force(direction),
                         na.value = force(na.value),
                         lockcells = force(lockcells)),
                    class = c("condformat_rule", "rule_fill_discrete"))
  return(rule)
}

#' Fill column with discrete colors (standard evaluation)
#'
#' @family rule
#' @param columns a character vector with the column names or a list with
#'                dplyr select helpers given as formulas or a combination of both
#' @param expression a formula to be evaluated with the data that will be used
#'                   to determine which cells are to be coloured. See the examples
#'                   to use it programmatically
#' @inheritParams rule_fill_discrete
#'
#' @export
#' @examples
#' data(iris)
#' condformat(iris[c(1,51,101), ]) +
#'  rule_fill_discrete_(columns=c("Species"))
#' condformat(iris[c(1,51,101), ]) +
#'  rule_fill_discrete_("Species", expression=~Sepal.Length > 6)
#'
#' # Use it programmatically:
#' color_column_larger_than_threshold <- function(x, column, threshold) {
#'   condformat(x) +
#'     rule_fill_discrete_(column,
#'      expression=~ uq(as.name(column))> uq(threshold))
#' }
#' color_column_larger_than_threshold(iris[c(1,51,101),], "Sepal.Length", 6.3)
#'
#' condformat(iris[c(1,51,101),]) +
#'  rule_fill_discrete_(columns = list(~dplyr::starts_with("Petal"), "Species"),
#'                      expression=~Species)
#'
#' # Custom discrete color values can be specified with a function. The function takes
#' # the whole column and returns a vector with the colours.
#' color_pick <- function(column) {
#'   sapply(column,
#'     FUN = function(value) {
#'       if (value < 4.7) {
#'         return("red")
#'       } else if (value < 5.0) {
#'         return("yellow")
#'       } else {
#'         return("green")
#'       }
#'     })
#' }
#' condformat(head(iris)) +
#'    rule_fill_discrete_("Sepal.Length", ~ color_pick(Sepal.Length), colours = identity)
#'
rule_fill_discrete_ <- function(columns,
                                expression = ~.,
                                colours = NA,
                                h = c(0, 360) + 15, c = 100, l = 65,
                                h.start = 0, direction = 1, na.value = "#FFFFFF",
                                lockcells = FALSE) {

  col_expr <- parse_columns_and_expression_(columns, expression)
  rule <- structure(list(columns = col_expr[["columns"]],
                         expression = col_expr[["expression"]],
                         colours = force(colours),
                         h = force(h),
                         c = force(c), l = force(l),
                         h.start = force(h.start),
                         direction = force(direction),
                         na.value = force(na.value),
                         lockcells = force(lockcells)),
                    class = c("condformat_rule", "rule_fill_discrete_"))
  return(rule)
}



applyrule.rule_fill_discrete <- function(rule, finalformat, xfiltered, xview, ...) {
  columns <- dplyr::select_vars_(colnames(xview), rule$columns)
  values_determining_color <- as.factor(lazyeval::lazy_eval(rule$expression, data = xfiltered))
  values_determining_color <- rep(values_determining_color, length.out = nrow(xfiltered))
  rule_fill_discrete_common(rule, finalformat, xfiltered, xview, columns,
                            values_determining_color)
}

applyrule.rule_fill_discrete_ <- function(rule, finalformat, xfiltered, xview, ...) {
  columns <- dplyr::select_vars_(colnames(xview), rule$columns)
  if (!lazyeval::is_formula(rule$expression)) {
    values_determining_color <- as.factor(rule$expression)
  } else {
    values_determining_color <- as.factor(lazyeval::f_eval(f = rule$expression, data = xfiltered))
    values_determining_color <- rep(values_determining_color, length.out = nrow(xfiltered))
  }
  rule_fill_discrete_common(rule, finalformat, xfiltered, xview, columns,
                            values_determining_color)
}

rule_fill_discrete_common <- function(rule, finalformat, xfiltered, xview,
                                      columns, values_determining_color) {
  colours_for_values <- NA
  if (identical(rule$colours, NA)) {
    # colours not given: Create a palette
    number_colours <- length(unique(values_determining_color))
    col_scale <- scales::hue_pal(h = rule$h, c = rule$c, l = rule$l,
                                 h.start = rule$h.start,
                                 direction = rule$direction)(number_colours)
    colours_for_values <- col_scale[as.integer(values_determining_color)]
  } else if (is.character(rule$colours)) {
    colours_for_values <- rule$colours[match(values_determining_color, names(rule$colours))]
  } else if (is.function(rule$colours)) {
    colours_for_values <- rule$colours(values_determining_color)
    if (is.factor(colours_for_values)) {
      colours_for_values <- as.character(colours_for_values)
    }
  }
  colours_for_values[is.na(colours_for_values)] <- rule$na.value
  stopifnot(identical(length(colours_for_values), nrow(xview)))
  colours_for_values <- matrix(colours_for_values,
                               nrow = nrow(xview), ncol = ncol(xview), byrow = FALSE)

  finalformat <- fill_css_field_by_cols(finalformat,
                                        "background-color", colours_for_values,
                                        columns, xview, rule$lockcells)
  return(finalformat)
}

