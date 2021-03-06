#' HERE Routing API: Calculate Route
#'
#' Calculates route geometries (\code{LINESTRING}) between given pairs of points using the HERE 'Routing' API.
#' Routes can be created for various transport modes, as for example 'car' or 'bicycle',
#' incorporating current traffic information, if available.
#' For routes using the transport mode \code{"car"} a vehicle consumption model can be specified,
#' to obtain an estimate of the consumption.
#'
#' @references
#' \href{https://developer.here.com/documentation/routing-api/8.16.0/dev_guide/index.html}{HERE Routing API: Calculate Route}
#'
#' @param origin \code{sf} object, the origin locations of geometry type \code{POINT}.
#' @param destination \code{sf} object, the destination locations of geometry type \code{POINT}.
#' @param datetime \code{POSIXct} object, datetime for the departure (or arrival if \code{arrival = TRUE}).
#' @param arrival boolean, calculate routes for arrival at the defined time (\code{default = FALSE})?
#' @param results numeric, maximum number of suggested routes (Valid range: 1 and 7).
#' @param routing_mode character, set the routing type: \code{"fast"} or \code{"short"} (\code{default = "fast"}).
#' @param transport_mode character, set the transport mode: \code{"car"}, \code{"truck"}, \code{"pedestrian"}, \code{"bicycle"} or \code{scooter} (\code{default = "car"}).
#' @param traffic boolean, use real-time traffic or prediction in routing (\code{default = TRUE})? If no traffic is selected, the \code{datetime} is set to \code{"any"} and the request is processed independently from time.
#' @param consumption_model character, specify the consumption model of the vehicle, see \href{https://developer.here.com/documentation/routing-api/8.16.0/dev_guide/topics/use-cases/consumption-model.html}{consumption model} for more information (\code{default = NULL} a average electric car is set).
#' @param url_only boolean, only return the generated URLs (\code{default = FALSE})?
#' @param type character, 'type' is deprecated, use 'routing_mode' instead.
#' @param mode character, 'mode' is deprecated, use 'transport_mode' instead.
#'
#' @return
#' An \code{sf} object containing the requested routes.
#' @export
#'
#' @examples
#' # Provide an API Key for a HERE project
#' set_key("<YOUR API KEY>")
#'
#' # Get all from - to combinations from POIs
#' to <- poi[rep(seq_len(nrow(poi)), nrow(poi)), ]
#' from <- poi[rep(seq_len(nrow(poi)), each = nrow(poi)),]
#' idx <- apply(to != from, any, MARGIN = 1)
#' to <- to[idx, ]
#' from <- from[idx, ]
#'
#' # Routing
#' routes <- route(
#'   origin = from, destination = to, results = 3,
#'   transport_mode = "car", url_only = TRUE
#' )
route <- function(origin, destination, datetime = Sys.time(), arrival = FALSE,
                  results = 1, routing_mode = "fast", transport_mode = "car",
                  traffic = TRUE, consumption_model = NULL, url_only = FALSE,
                  type, mode, waypoints = NULL) {

  # Deprecated parameters
  if (!missing("type")) {
    warning("'type' is deprecated, use 'routing_mode' instead.")
    routing_mode <- type
  }
  if (!missing("mode")) {
    warning("'mode' is deprecated, use 'transport_mode' instead.")
    transport_mode <- mode
  }

  # Checks
  .check_points(origin)
  .check_points(destination)
  .check_input_rows(origin, destination)
  .check_datetime(datetime)
  .check_boolean(arrival)
  .check_numeric_range(results, 1, 7)
  .check_routing_mode(routing_mode)
  .check_transport_mode(transport_mode, request = "route")
  .check_boolean(traffic)
  .check_boolean(url_only)

  # Arrival time is not yet supported by the API
  if (arrival) {
    message("Arrival time is not supported at the moment on this endpoint (v8.16.0), please set 'arrival = FALSE'.")
    return(NULL)
  }

  # Add API key
  url <- .add_key(
    url = "https://router.hereapi.com/v8/routes?"
  )

  # Add point coordinates
  orig_coords <- sf::st_coordinates(
    sf::st_transform(origin, 4326)
  )
  dest_coords <- sf::st_coordinates(
    sf::st_transform(destination, 4326)
  )
  url = paste0(
    url,
    "&origin=",
    orig_coords[, 2], ",", orig_coords[, 1],
    "&destination=",
    dest_coords[, 2], ",", dest_coords[, 1]
  )

  if (!is.null(waypoints)){
    if (any(class(waypoints)=="sf")){
      for (i in c(1:nrow(waypoints))){
        url = paste0(
          url,
          "&via=",
          sf::st_coordinates(waypoints[i,])[,2],
          ",",
          sf::st_coordinates(waypoints[i,])[,1]
        )
      }
    }
  }

  # Add departure or arrival time depending on traffic option
  if (traffic) {
    url <- .add_datetime(
      url,
      datetime,
      if (arrival) "arrivalTime" else "departureTime"
    )
  } else {
    url <- paste0(
      url,
      "&departureTime=any"
    )
  }

  # Add transport mode
  url <- .add_transport_mode(url, transport_mode)

  # Add alternatives (results minus 1)
  url <- paste0(
    url,
    "&alternatives=",
    results - 1
  )

  # Add consumption model if specified, otherwise set to default electric vehicle
  if(is.null(consumption_model)) {
    url <- paste0(
      url,
      "&ev[freeFlowSpeedTable]=0,0.239,27,0.239,45,0.259,60,0.196,75,0.207,90,0.238,100,0.26,110,0.296,120,0.337,130,0.351,250,0.351",
      "&ev[trafficSpeedTable]=0,0.349,27,0.319,45,0.329,60,0.266,75,0.287,90,0.318,100,0.33,110,0.335,120,0.35,130,0.36,250,0.36",
      "&ev[ascent]=9",
      "&ev[descent]=4.3",
      "&ev[auxiliaryConsumption]=1.8"
    )
  } else {
    url <- paste0(
      url,
      consumption_model
    )
  }

  # Request polyline and summary
  url = paste0(
    url,
    "&return=",
    "polyline,elevation,travelSummary"
  )

  # Return urls if chosen
  if (url_only) return(url)

  # Request and get content
  data <- .get_content(
    url = url
  )
  if (length(data) == 0) return(NULL)

  # Extract information
  routes <- .extract_routes(data)

  # Checks success
  if (is.null(routes)) {
    message("No routes found.")
    return(NULL)
  }

  # Postprocess
  #routes <- routes[routes$rank <= results, ]
  departure <- NULL
  routes[, c("departure", "arrival") := list(
    .parse_datetime_tz(departure, tz = attr(datetime, "tzone")),
    .parse_datetime_tz(arrival, tz = attr(datetime, "tzone")))]
  rownames(routes) <- NULL

  # Create sf object
  return(
    sf::st_as_sf(
      as.data.frame(routes),
      sf_column_name = "geometry",
      crs = 4326
    )
  )
}

.extract_routes <- function(data) {
  ids <- .get_ids(data)
  count <- 0

  template <- data.table::data.table(
    id = numeric(),
    rank = numeric(),
    departure = character(),
    arrival = character(),
    type = character(),
    mode = character(),
    distance = integer(),
    duration = integer(),
    duration_base = integer(),
    consumption = numeric(),
    geometry = character()
  )

  # Routes
  routes <- data.table::rbindlist(
    append(list(template),
      lapply(data, function(con) {
        count <<- count + 1

        # Parse JSON
        df <- jsonlite::fromJSON(con)
        if (is.null(df$routes$sections)) {return(NULL)}

        # Routes
        rank <- 0
        routes <- data.table::data.table(
          id = ids[count],

          # Segments
          data.table::rbindlist(
            lapply(df$routes$sections, function(sec) {
              rank <<- rank + 1
              data.table::data.table(
                rank = rank,
                departure = sec$departure$time,
                arrival = sec$arrival$time,
                type = sec$type,
                mode = sec$transport$mode,
                distance = sec$travelSummary$length,
                duration = sec$travelSummary$duration,
                duration_base = sec$travelSummary$baseDuration,
                consumption = if (is.null(sec$travelSummary$consumption)) {NA} else {sec$travelSummary$consumption},
                geometry = sec$polyline
              )
            }), fill = TRUE
          )
        )
      })
    ), fill = TRUE
  )

  # Check success
  if (nrow(routes) < 1) {return(NULL)}

  # Decode flexible polyline encoding to LINESTRING
  geometry <- NULL
  routes[, "geometry" := sf::st_geometry(
    flexpolyline::decode_sf(geometry, 4326))
  ]
  return(routes)
}
