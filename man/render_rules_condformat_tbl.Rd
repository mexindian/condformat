% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/condformat_render.R
\name{render_rules_condformat_tbl}
\alias{render_rules_condformat_tbl}
\title{Renders the css matrix to format the xview table}
\usage{
render_rules_condformat_tbl(rules, xfiltered, xview, format)
}
\arguments{
\item{rules}{List of rules to be applied}

\item{xfiltered}{Like xview, but with all the columns (rules
will use columns that won't be printed)}

\item{xview}{Data frame with the rows and columns that will be printed}

\item{format}{Output format (either "html" or "latex")}
}
\value{
List with the CSS information
}
\description{
Renders the css matrix to format the xview table
}

