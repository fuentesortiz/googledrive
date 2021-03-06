#' List contents of a folder or Team Drive
#'
#' List the contents of a folder or Team Drive, recursively or not. This is a
#' thin wrapper around [drive_find()], that simply adds one constraint: the
#' search is limited to direct or indirect children of `path`.
#'
#' @param path Specifies a single folder on Google Drive whose contents you want
#'   to list. Can be an actual path (character), a file id or URL marked with
#'   [as_id()], or a [`dribble`]. If it is a Team Drive or is a folder on a Team
#'   Drive, it must be passed as a [`dribble`].
#' @param ... Any parameters that are valid for [drive_find()].
#' @param recursive Logical, indicating if you want only direct children of
#'   `path` (`recursive = FALSE`, the default) or all children, including
#'   indirect (`recursive = TRUE`).
#'
#' @template dribble-return
#' @export
#' @examples
#' \dontrun{
#' ## get contents of the folder 'abc' (non-recursive)
#' drive_ls("abc")
#'
#' ## get contents of folder 'abc' whose names contain the letters 'def'
#' drive_ls(path = "abc", pattern = "def")
#'
#' ## get all Google spreadsheets in folder 'abc'
#' ## whose names contain the letters 'def'
#' drive_ls(path = "abc", pattern = "def", type = "spreadsheet")
#'
#' ## get all the files below 'abc', recursively, that are starred
#' drive_ls(path = "abc", q = "starred = true", recursive = TRUE)
#' }
drive_ls <- function(path = NULL, ..., recursive = FALSE) {
  stopifnot(is.logical(recursive), length(recursive) == 1)
  if (is.null(path)) {
    return(drive_find(...))
  }

  if (is_path(path)) {
    path <- append_slash(path)
  }
  path <- as_dribble(path)
  path <- confirm_single_file(path)

  params <- rlang::list2(...)
  if (is_team_drivy(path)) {
    if (is_team_drive(path)) {
      params[["team_drive"]] <- as_id(path)
    } else {
      params[["team_drive"]] <- as_id(
        path[["drive_resource"]][[1]][["teamDriveId"]]
      )
    }
  }

  parent <- path[["id"]]
  if (isTRUE(recursive)) {
    parent <- c(parent, folders_below(parent))
  }
  parent <- glue("{sq(parent)} in parents")
  parent <- glue("({or(parent)})")
  params[["q"]] <- append(params[["q"]], parent)

  rlang::exec(drive_find, !!!params)
}

folders_below <- function(id) {
  folder_kids <- folder_kids_of(id)
  if (length(folder_kids) == 0) {
    character()
  } else {
    c(
      folder_kids,
      unlist(lapply(folder_kids, folders_below), recursive = FALSE)
    )
  }
}

folder_kids_of <- function(id) {
  drive_find(
    type = "folder",
    q = glue("{sq(id)} in parents"),
    fields = prep_fields(c("kind", "name", "id"))
  )[["id"]]
}
