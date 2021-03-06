##' Ensures that specified IDs are correctly formatted
##'
##' @param id a character string specifying the Google Scholar ID.
##' If multiple ids are specified, only the first value is used and a
##' warning is generated.
##' @export
##' @importFrom httr GET
##' @keywords internal
tidy_id <- function(id) {
    if (length(id)!=1) {
        id <- id[1]
        msg <- sprintf("Only one ID at a time; retrieving %s", id)
        warning(msg)
    }

    return(id)
}


#' Recursively try to GET a Google Scholar Page storing session cookies
#'
#' see \code{\link{scholar-package}} documentation for details about Scholar
#' session cookies.
#'
#' @param url URL to fetch
#' @param attempts_left The number of times to try and fetch the page
#'
#' @return an \code{httr::\link{response}} object
#' @seealso \code{httr::\link{GET}}
#' @export
get_scholar_resp <- function(url, attempts_left = 5) {

    stopifnot(attempts_left > 0)

    resp <- httr::GET(url, handle = scholar_handle())

    # On a successful GET, return the response
    if (httr::status_code(resp) == 200) {
        resp
    } else if(httr::status_code(resp) == 429){
      stop("Response code 429. Google is rate limiting you for making too many requests too quickly.")
    } else if (attempts_left == 1) { # When attempts run out, stop with an error
        stop("Cannot connect to Google Scholar. Is the ID you provided correct?")
    } else { # Otherwise, sleep a second and try again
        Sys.sleep(1)
        get_scholar_resp(url, attempts_left - 1)
    }
}

# get a curl handle with Google scholar cookies set
scholar_handle <- function() {
    if (getOption("scholar_call_home")) {
        sample_url <- "https://scholar.google.com/citations?user=B7vSqZsAAAAJ"
        sink <- GET(sample_url)
        options("scholar_call_home"=FALSE, "scholar_handle"=sink)
    }
    getOption("scholar_handle")
}

## We can use this function through the package to compose
## a url by only providing the id
compose_url <- function(id, url_template) {
    if (is.na(id)) return(NA_character_)
    id <- tidy_id(id)
    url <- sprintf(url_template, id)

    url
}

# Extract the google scholar id of a url
grab_id <- function(url) {
    stringr::str_extract(url, "(?<=user=)[^=]*")
}
