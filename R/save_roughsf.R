#' Save roughsf plot to file
#' @param rsf result from calling the function `roughsf`
#' @param file filename
#' @param background string giving the html background color
#' @export
save_roughsf <- function(rsf,file,background = "white"){
  if(!requireNamespace("pagedown", quietly = TRUE)){
    stop("pagedown is needed for this function to work. Please install it.", call. = FALSE)
  }
  tfile <- tempfile(fileext = ".html")
  format <- substr(file,nchar(file)-2,nchar(file))
  htmlwidgets::saveWidget(rsf, file = tfile,background = background,selfcontained = TRUE)
  suppressMessages(pagedown::chrome_print(tfile,output=file,format=format,selector = "canvas#canvas",wait=4))
  suppressMessages(file.remove(tfile))
}
