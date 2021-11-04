#' Create a rough map
#' @description plot a sf map using rough.js
#' @param object sf object
#' @param roughness numeric vector for roughness of lines
#' @param bowing numeric vector for bowing of lines
#' @param simplification simplify drawings (remove points from objects)
#' @param font font size and font family for labels
#' @param title optional title of the map
#' @param width width
#' @param height height
#' @param elementId DOM id
#' @param chunk_name markdown specific
#' @details the function recognizes the following attributes:
#'
#' * \emph{fill} shape fill color
#' * \emph{color} shape stroke color
#' * \emph{stroke} stroke size
#' * \emph{fillstyle} one of "hachure", "solid", "zigzag", "cross-hatch", "dots", "dashed", "zigzag-line"
#' * \emph{label} label (not implemented yet)
#'
#' Default values are used if one of the attributes is not found.
#'
#' The result of a roughnet call can be printed to file with `save_roughnet()`
#'
#' More details on roughjs can be found on https://github.com/rough-stuff/rough/wiki
#' @export
roughsf <- function(object,
                    roughness = 1, bowing = 1, simplification = 1,
                    font = "30px Arial",
                    title = NULL,
                    title_font = "30px Arial",
                    width = NULL, height = NULL, elementId = NULL,chunk_name = "canvas") {

  # prepare styles ----
  if(!"fill" %in% names(object)){
    vfill <- "black"
  } else{
    vfill <- object[["fill"]]
  }
  if(!"color" %in% names(object)){
    vcol <- "black"
  } else{
    vcol <- object[["color"]]
  }

  if(!"stroke" %in% names(object)){
    vstroke <- 1
  } else{
    vstroke <- object[["stroke"]]
  }

  if(!"fillstyle" %in% names(object)){
    vfillstyle <- "hachure"
  } else{
    vfillstyle <- object[["fillstyle"]]
  }

  #prepare data----
  types <- sf::st_geometry_type(object)
  if(any(types=="MULTIPOLYGON" | types=="MULTILINESTRING")){
    stop("MULTIPOLYGONS and MULTILINESTRINGS are not supported. Use `sf::st_cast()` first.")
  }
  coords <- sf::st_coordinates(object)
  if(is.null(width)){
    width <- 800
    coords[,1] <- normalise(coords[,1], to = c(100,700))
  } else{
    coords[,1] <- normalise(coords[,1], to = c(width*0.1,width*0.9))
  }
  if(is.null(height)){
    height <- 600
    coords[,2] <- normalise(coords[,2], to = c(500,100))
  } else{
    coords[,2] <- normalise(coords[,2], to = c(height*0.9,height*0.1))
  }
  nobj <- nrow(object)#max(coords[,4])
  mobj <- ncol(coords)
  path_string <- rep("",nobj)
  coords_list <- split(coords[,1:2],coords[,mobj])

  for(i in 1:nobj){
    xy <- matrix(coords_list[[i]],ncol=2)
    path_string[i] <- paste0("M ",paste0(apply(xy,1,paste0,collapse=" "),collapse=" L "))
    if(types[i]=="POLYGON"){
      path_string[i] <- paste0(path_string[i]," z")
    }
  }

  #prepare final data
  rough_df <- data.frame(
    xy  = path_string,
    x = 0,
    y = 0,
    shape=as.character(types),
    color = vcol,
    fill  = vfill,
    fillstyle = vfillstyle,
    width = vstroke,
    label="")

  if(!is.null(title)){
    title_df <- data.frame(xy="",x=width/2,y=50,shape="TITLE",color="black",fill="",fillstyle="",width=0,label=title)
    rough_df <- rbind(rough_df,title_df)
  }
  rough_df$roughness <- roughness
  rough_df$bowing <- bowing
  rough_df$simplification <- simplification

  x <- list(
    data=jsonlite::toJSON(rough_df),
    font=font,
    title_font=title_font,
    id=chunk_name
  )

  # create widget
  htmlwidgets::createWidget(
    name = 'roughsf',
    x = x,
    width = width,
    height = height,
    package = 'roughsf',
    elementId = elementId
  )
}

normalise <- function (x, from = range(x), to = c(0, 1))
{
  x <- (x - from[1])/(from[2] - from[1])
  if (!identical(to, c(0, 1))) {
    x <- x * (to[2] - to[1]) + to[1]
  }
  x
}

#<a href="https://www.freepik.com/photos/background">Background photo created by aopsan - www.freepik.com</a>
