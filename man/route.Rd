% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/route.R
\name{route}
\alias{route}
\title{HERE Routing API: Calculate Route}
\usage{
route(
  origin,
  destination,
  datetime = Sys.time(),
  arrival = FALSE,
  results = 1,
  routing_mode = "fast",
  transport_mode = "car",
  traffic = TRUE,
  consumption_model = NULL,
  url_only = FALSE,
  type,
  mode
)
}
\arguments{
\item{origin}{\code{sf} object, the origin locations of geometry type \code{POINT}.}

\item{destination}{\code{sf} object, the destination locations of geometry type \code{POINT}.}

\item{datetime}{\code{POSIXct} object, datetime for the departure (or arrival if \code{arrival = TRUE}).}

\item{arrival}{boolean, calculate routes for arrival at the defined time (\code{default = FALSE})?}

\item{results}{numeric, maximum number of suggested routes (Valid range: 1 and 7).}

\item{routing_mode}{character, set the routing type: \code{"fast"} or \code{"short"} (\code{default = "fast"}).}

\item{transport_mode}{character, set the transport mode: \code{"car"}, \code{"truck"}, \code{"pedestrian"}, \code{"bicycle"} or \code{scooter} (\code{default = "car"}).}

\item{traffic}{boolean, use real-time traffic or prediction in routing (\code{default = TRUE})? If no traffic is selected, the \code{datetime} is set to \code{"any"} and the request is processed independently from time.}

\item{consumption_model}{character, specify the consumption model of the vehicle, see \href{https://developer.here.com/documentation/routing-api/8.16.0/dev_guide/topics/use-cases/consumption-model.html}{consumption model} for more information (\code{default = NULL} a average electric car is set).}

\item{url_only}{boolean, only return the generated URLs (\code{default = FALSE})?}

\item{type}{character, 'type' is deprecated, use 'routing_mode' instead.}

\item{mode}{character, 'mode' is deprecated, use 'transport_mode' instead.}
}
\value{
An \code{sf} object containing the requested routes.
}
\description{
Calculates route geometries (\code{LINESTRING}) between given pairs of points using the HERE 'Routing' API.
Routes can be created for various transport modes, as for example 'car' or 'bicycle',
incorporating current traffic information, if available.
For routes using the transport mode \code{"car"} a vehicle consumption model can be specified,
to obtain an estimate of the consumption.
}
\examples{
# Provide an API Key for a HERE project
set_key("<YOUR API KEY>")

# Get all from - to combinations from POIs
to <- poi[rep(seq_len(nrow(poi)), nrow(poi)), ]
from <- poi[rep(seq_len(nrow(poi)), each = nrow(poi)),]
idx <- apply(to != from, any, MARGIN = 1)
to <- to[idx, ]
from <- from[idx, ]

# Routing
routes <- route(
  origin = from, destination = to, results = 3,
  transport_mode = "car", url_only = TRUE
)
}
\references{
\href{https://developer.here.com/documentation/routing-api/8.16.0/dev_guide/index.html}{HERE Routing API: Calculate Route}
}
