% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/station.R
\name{station}
\alias{station}
\title{HERE Public Transit API: Find Stations Nearby}
\usage{
station(poi, radius = 500, results = 50, url_only = FALSE)
}
\arguments{
\item{poi}{\code{sf} object, Points of Interest (POIs) of geometry type \code{POINT}.}

\item{radius}{numeric, the search radius in meters (\code{default = 500}).}

\item{results}{numeric, maximum number of suggested public transport stations (Valid range: 1 and 50, \code{default = 50}).}

\item{url_only}{boolean, only return the generated URLs (\code{default = FALSE})?}
}
\value{
An \code{sf} object containing the requested stations with the corresponding line information.
}
\description{
Retrieve stations with the corresponding line information around given locations using the HERE 'Public Transit' API.
}
\examples{
# Provide an API Key for a HERE project
set_key("<YOUR API KEY>")

# Stations
stations <- station(poi = poi, url_only = TRUE)
}
\references{
\href{https://developer.here.com/documentation/public-transit/dev_guide/station-search/index.html}{HERE Public Transit API: Station Search}
}
