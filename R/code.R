#' Code
#' 
#' Generate code for a blockr block
#' 
#' @param x Block object.
#' @param file File ([new_file]) to use for context.
#' @param ... Ignored.
#' 
#' @export
code <- function(x, file, ...) UseMethod("code")

#' @export
code.block <- function(x, file, ...) {
  blockr::generate_code(x) |>
    deparse()
}

#' @export
code.markdown_block <- function(x, file, ...) {
  prog <- blockr::generate_code(x)
  output <- eval(prog)

  if(length(output$original))
    return(output$original)

  return(output$text)
}

safe_code <- function(x, file, ...) {
  ok <- safe_eval(code(x, file, ...))

  if(is_error(ok)) return(ok)
  warn_if(ok)

  return(ok)
}

#' Code Fence
#' 
#' Generate code fence for a blockr stack
#' 
#' @param x Stack object.
#' @param name Name of the stack.
#' @param code Code generated for the stack.
#' @param file File ([new_file]) to use for context.
#' @param ... Ignored.
#' 
#' @export
code_fence <- function(x, file, name, code, ...) UseMethod("code_fence")

#' @export
code_fence.stack <- function(x, file, name, code, ...) {
  echo <- !inherits(file, "export_rmarkdown_output")
  has_md <- stack_has_markdown_block(x)
  if(has_md) {
    return(code)
  }

  ends_rtables <- stack_ends_rtables_block(x)
  if (ends_rtables) {
    return(paste0(
      "```{r ", name, ", warning=FALSE, message=FALSE, echo=", echo, "}\nout <-", code, 
      "\nif(length(out$gt)) {out$gt",
      "\n}else if(length(out$rtables)) {flextable::autofit(rtables::tt_to_flextable(out$rtables))}",
      "\n```")
    )
  }

  extra <- ""
  has_table <- stack_has_composer_block(x)
  if(has_table) {
    code <- paste0(code, "%>% {composer::generate_table(.)$formatted_table}")
    extra <- ", results='asis'"
  }

  return(paste0("```{r ", name, ", warning=FALSE, message=FALSE, echo=", echo, extra, "}\n", code, "\n```"))
}

safe_code_fence <- function(x, ...) {
  ok <- safe_eval(code_fence(x, ...))

  if(is_error(ok)) return(ok)
  warn_if(ok)

  return(ok)
}

stack_ends_rtables_block <- function(stack) {
  last_block <- stack[[length(stack)]]

  return(inherits(last_block, "rtables_block"))
}

stack_has_markdown_block <- function(stack) {
  for (block in stack) {
    if(inherits(block, "markdown_block")) {
      return(TRUE)
    }
  }

  return(FALSE)
}

stack_has_composer_block <- function(stack) {
  for (block in stack) {
    if(inherits(block, "table_block")) {
      return(TRUE)
    }
  }

  return(FALSE)
}
