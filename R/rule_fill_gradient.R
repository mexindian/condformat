#' Fill column with sequential colour gradient
#'
#' Fills the background color of a column using a gradient based on
#' the values given by an expression
#'
#' @family rule
#'
#' @param ... Comma separated list of unquoted column names.
#'            If \code{expression} is also given, then this list can use any of the
#'            \code{\link[dplyr]{select}} syntax possibilities.
#' @param expression an expression to be evaluated with the data.
#'                   It should evaluate to a numeric vector,
#'                   that will be used to determine the colour gradient level.
#' @inheritParams scales::seq_gradient_pal
#' @param limits range of limits that the gradient should cover
#' @param na.value fill color for missing values
#' @param lockcells logical value determining if no further rules should be applied to the affected cells.
#'
#' @return The condformat_tbl object, with the added formatting information
#' @examples
#' data(iris)
#' condformat(iris[c(1:5, 70:75, 120:125), ]) +
#'   rule_fill_gradient(Sepal.Length) +
#'   rule_fill_gradient(Species, expression=Sepal.Length - Sepal.Width)
#' @export
rule_fill_gradient <- function(...,
                               expression,
                               low = "#132B43", high = "#56B1F7",
                               space = "Lab",
                               na.value = "#7F7F7F",
                               limits=NA,
                               lockcells=FALSE) {
  columns <- lazyeval::lazy_dots(...)
  if (missing(expression)) {
    if (length(columns) > 1) {
      warning("rule_fill_gradient applied to multiple variables, using the first given variable as expression")
    }
    expression <- columns[[1]]
  } else {
    expression <- lazyeval::lazy(expression)
  }

  rule <- structure(list(columns = columns, expression = expression,
                         low = force(low),
                         high = force(high),
                         space = force(space),
                         na.value = force(na.value),
                         limits = force(limits),
                         lockcells = force(lockcells)),
                    class = c("condformat_rule", "rule_fill_gradient"))
  return(rule)
}


#' Fill column with sequential colour gradient (standard evaluation)
#'
#' Fills the background color of a column using a gradient based on
#' the values given by an expression
#'
#' @family rule
#' @param columns a character vector with the column names or a list with
#'                dplyr select helpers given as formulas or a combination of both
#' @param expression a formula to be evaluated with the data that will be used
#'                   to determine which cells are to be coloured. See the examples
#'                   to use it programmatically
#' @inheritParams scales::seq_gradient_pal
#' @inheritParams rule_fill_gradient
#' @export
#' @examples
#' data(iris)
#' condformat(iris[1:5,]) + rule_fill_gradient_(columns=c("Sepal.Length"))
#' ex1 <- condformat(iris[1:5,]) +
#'   rule_fill_gradient_("Species", expression=~Sepal.Length-Sepal.Width)
#' # Use it programmatically:
#' gradient_color_column1_minus_column2 <- function(x, column_to_paint, column1, column2) {
#'   condformat(x) +
#'     rule_fill_discrete_(column_to_paint,
#'      expression=~ uq(as.name(column1)) - uq(as.name(column2)))
#' }
#' ex2 <- gradient_color_column1_minus_column2(iris[1:5,], "Species", "Sepal.Length", "Sepal.Width")
#' stopifnot(ex1 == ex2)
rule_fill_gradient_ <- function(columns,
                                expression=~.,
                                low = "#132B43", high = "#56B1F7",
                                space = "Lab",
                                na.value = "#7F7F7F",
                                limits = NA,
                                lockcells = FALSE) {
  col_expr <- parse_columns_and_expression_(columns, expression)
  rule <- structure(list(columns = col_expr[["columns"]],
                         expression = col_expr[["expression"]],
                         low = force(low), high = force(high),
                         space = force(space), na.value = force(na.value),
                         limits = force(limits), lockcells = force(lockcells)),
                    class = c("condformat_rule", "rule_fill_gradient_"))
  return(rule)
}

applyrule.rule_fill_gradient <- function(rule, finalformat, xfiltered, xview, ...) {
  columns <- dplyr::select_vars_(colnames(xview), rule$columns)
  values_determining_color <- lazyeval::lazy_eval(rule$expression, xfiltered)
  values_determining_color <- rep(values_determining_color, length.out = nrow(xfiltered))
  rule_fill_gradient_common(rule, finalformat, xview, columns, values_determining_color)
}

applyrule.rule_fill_gradient_ <- function(rule, finalformat, xfiltered, xview, ...) {
  columns <- dplyr::select_vars_(colnames(xview), rule$columns)
  values_determining_color <- lazyeval::f_eval(f = rule$expression, data = xfiltered)
  values_determining_color <- rep(values_determining_color, length.out = nrow(xfiltered))
  rule_fill_gradient_common(rule, finalformat, xview, columns, values_determining_color)
}

rule_fill_gradient_common <- function(rule, finalformat, xview,
                                      columns, values_determining_color) {
  if (identical(rule$limits, NA)) {
    limits <- range(values_determining_color, na.rm = TRUE)
  } else {
    limits <- rule$limits
  }

  col_scale <- scales::seq_gradient_pal(low = rule$low, high = rule$high, space = rule$space)

  values_rescaled <- scales::rescale(x = values_determining_color, from = limits)
  colours_for_values <- col_scale(values_rescaled)
  stopifnot(identical(length(colours_for_values), nrow(xview)))
  colours_for_values <- matrix(colours_for_values,
                               nrow = nrow(xview), ncol = ncol(xview), byrow = FALSE)

  finalformat <- fill_css_field_by_cols(finalformat, "background-color",
                                        colours_for_values, columns,
                                        xview, rule$lockcells)
  return(finalformat)
}
