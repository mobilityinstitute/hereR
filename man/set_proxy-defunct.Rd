% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/defunct.R
\name{set_proxy-defunct}
\alias{set_proxy-defunct}
\title{Proxy Configuration}
\usage{
set_proxy(proxy, proxyuserpwd)
}
\arguments{
\item{proxy}{character, the URL of the proxy (\code{"https://your-proxy.net:port/"}).}

\item{proxyuserpwd}{character, user and password for the authentication (\code{"user:pwd"}).}
}
\value{
None.
}
\description{
If a proxy is needed, for example because the computer is behind a corporate proxy,
it can be set as follows: \code{proxy = "http://your-proxy.net:port/"} or \code{"https://your-proxy.net:port/"} and \code{"proxyuserpwd" = "user:pwd"}.
}
\seealso{
\code{\link{hereR-defunct}}
}
\keyword{internal}
