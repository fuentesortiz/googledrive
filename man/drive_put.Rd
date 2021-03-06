% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/drive_put.R
\name{drive_put}
\alias{drive_put}
\title{PUT new media into a Drive file}
\usage{
drive_put(media, path = NULL, name = NULL, ..., type = NULL, verbose = TRUE)
}
\arguments{
\item{media}{Character, path to the local file to upload.}

\item{path}{Specifies target destination for the new file on Google
Drive. Can be an actual path (character), a file id marked with \code{\link[=as_id]{as_id()}},
or a \code{\link{dribble}}. If specified as an actual path, it is best to explicitly
indicate if it's a folder by including a trailing slash, since it cannot
always be worked out from the context of the call. Will default to its local name.}

\item{name}{Character, new file name if not specified as part of
\code{path}. This will force \code{path} to be treated as a folder, even if it is
character and lacks a trailing slash. Will default to its local name.}

\item{...}{Named parameters to pass along to the Drive API. Has the tidy dots
semantics that come from using \code{\link[rlang:list2]{rlang::list2()}}. You can affect the
metadata of the target file by specifying properties of the Files resource
via \code{...}. Read the "Request body" section of the Drive API docs for the
associated endpoint to learn about relevant parameters.}

\item{type}{Character. If \code{type = NULL}, a MIME type is automatically
determined from the file extension, if possible. If the source file is of a
suitable type, you can request conversion to Google Doc, Sheet or Slides by
setting \code{type} to \code{document}, \code{spreadsheet}, or \code{presentation},
respectively. All non-\code{NULL} values for \code{type} are pre-processed with
\code{\link[=drive_mime_type]{drive_mime_type()}}.}

\item{verbose}{Logical, indicating whether to print informative messages
(default \code{TRUE}).}
}
\value{
An object of class \code{\link{dribble}}, a tibble with one row per item.
}
\description{
PUTs new media into a Drive file, in the HTTP sense: if the file already
exists, we replace its content and we create a new file, otherwise. This is a
convenience wrapper around \code{\link[=drive_upload]{drive_upload()}} and \code{\link[=drive_update]{drive_update()}}. In
pseudo-code:\preformatted{target_filepath <- <determined from `path`, `name`, and `media`>
hits <- <get all Drive files at target_filepath>
if (no hits) \{
  drive_upload(media, path, name, type, ..., verbose)
\} else if (exactly 1 hit) \{
  drive_update(hit, media, ..., verbose)
\} else \{
  ERROR
\}
}
}
\examples{
\dontrun{
# create a local file to work with
local_file <- tempfile("drive_put_", fileext = ".txt")
writeLines(c("beginning", "middle"), local_file)

# PUT to a novel filepath --> drive_put() delegates to drive_upload()
file <- drive_put(local_file)

# update the local file
cat("end", file = local_file, sep = "\n", append = TRUE)

# PUT again --> drive_put() delegates to drive_update()
file <- drive_put(local_file)

# create a second file at this filepath
file2 <- drive_create(basename(local_file))

# PUT again --> ERROR
drive_put(local_file)

# clean-up
drive_find("drive_put_.+[.]txt") \%>\% drive_rm()
unlink(local_file)
}
}
