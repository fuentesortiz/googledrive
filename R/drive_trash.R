#' Move Drive files to or from trash
#' @template file-plural
#' @template verbose
#'
#' @template dribble-return
#' @export
#' @examples
#' \dontrun{
#' ## Create a file and put it in the trash.
#' file <- drive_upload(drive_example("chicken.txt"), "chicken-trash.txt")
#' drive_trash("chicken-trash.txt")
#'
#' ## Confirm it's in the trash
#' drive_find(trashed = TRUE)
#'
#' ## Remove it from the trash and confirm
#' drive_untrash("chicken-trash.txt")
#' drive_find(trashed = TRUE)
#'
#' ## Clean up
#' drive_rm("chicken-trash.txt")
#' }
drive_trash <- function(file, verbose = TRUE) {
  invisible(drive_toggle_trash(file, trash = TRUE, verbose = verbose))
}

#' @rdname drive_trash
#' @export
drive_untrash <- function(file, verbose = TRUE) {
  if (is_path(file)) {
    trash <- drive_find(trashed = TRUE)
    file <- trash[trash$name %in% file, ]
  }
  invisible(drive_toggle_trash(file, trash = FALSE, verbose = verbose))
}

drive_toggle_trash <- function(file, trash, verbose = TRUE) {
  VERB <- if (trash) "trash" else "untrash"
  VERBED <- paste0(VERB, "ed")

  file <- as_dribble(file)
  if (no_file(file)) {
    if (verbose) message_glue("No such files found to {VERB}.")
    return(invisible(dribble()))
  }

  out <- purrr::map(file$id, toggle_trash_one, trash = trash)
  out <- do.call(rbind, out)

  if (verbose) {
    files <- glue_data(out, "  * {name}: {id}")
    message_collapse(c(glue("Files {VERBED}:"), files))
  }
  invisible(out)
}

toggle_trash_one <- function(id, trash = TRUE) {
  request <- request_generate(
    endpoint = "drive.files.update",
    params = list(
      fileId = id,
      trashed = trash,
      fields = "*"
    )
  )
  response <- request_make(request, encode = "json")
  proc_res <- gargle::response_process(response)
  as_dribble(list(proc_res))
}

drive_reveal_trashed <- function(file) {
  confirm_dribble(file)
  if (no_file(file)) {
    return(
      put_column(dribble(), nm = "trashed", val = logical(), .after = "name")
    )
  }
  promote(file, "trashed")
}

#' Empty Drive Trash
#'
#' @description Caution, this will permanently delete files in your Drive trash.
#'
#' @template verbose
#' @export
drive_empty_trash <- function(verbose = TRUE) {
  files <- drive_find(trashed = TRUE)
  if (no_file(files)) {
    if (verbose) message("Your trash was already empty.")
    return(invisible(TRUE))
  }
  request <- request_generate(endpoint = "drive.files.emptyTrash")
  response <- request_make(request)
  success <- gargle::response_process(response)
  if (verbose) {
    if (success) {
      message_glue(
        "{nrow(files)} file(s) deleted from your Google Drive trash."
      )
    } else {
      message_glue("Empty trash appears to have failed.")
    }
  }
  invisible(success)
}
