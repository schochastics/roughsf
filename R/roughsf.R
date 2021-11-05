#' Create a rough map
#' @description plot a sf map using rough.js
#' @param layers an sf object or a list of sf object. each object should only contain one type of geometry.
#' @param roughness numeric vector for roughness of lines
#' @param bowing numeric vector for bowing of lines
#' @param simplification simplify drawings (remove points from objects)
#' @param font font size and font family for labels
#' @param title optional title of the map
#' @param title_font font size and font family for title
#' @param caption optional caption of the map
#' @param caption_font font size and font family for caption
#' @param width width
#' @param height height
#' @param elementId DOM id
#' @param chunk_name markdown specific
#' @details
#' The following attributes are supported for POLYGONS:
#' * \emph{fill} fill color
#' * \emph{color} stroke color
#' * \emph{stroke} stroke size
#' * \emph{fillstyle} one of "hachure", "solid", "zigzag", "cross-hatch", "dots", "dashed", "zigzag-line"
#' * \emph{fillweight} thickness of fillstyle (between 0 and 1)
#'
#' The following attributes are supported for LINESTRINGS:
#' * \emph{color} stroke color
#' * \emph{stroke} stroke size
#'
#' The following attributes are supported for POINTS:
#' * \emph{color} color of point
#' * \emph{size} size of point
#' * \emph{label} label to be added (optional)
#' * \emph{label_pos} position of label relative to point: (c)enter, (n)orth, (e)ast, (s)outh, (w)est (optional)
#'
#' Default values are used if one of the attributes is not found.
#'
#' The result of a roughsf call can be printed to file with `save_roughsf()`
#' @references
#' More details on roughjs can be found on https://github.com/rough-stuff/rough/wiki
#' @export
roughsf <- function(layers,
                    roughness = 1, bowing = 1, simplification = 1,
                    font = "30px Arial",
                    title = NULL, title_font = "30px Arial",
                    caption = NULL, caption_font="30px Arial",
                    width = NULL, height = NULL, elementId = NULL,chunk_name = "canvas") {

  if("sf"%in%class(layers)){
    layers <- list(layers)
  }
  n_layers <- length(layers)

  layer_types <- lapply(layers,sf::st_geometry_type)
  if(any(sapply(layer_types,function(l) length(unique(l)))>1)){
    stop("each layer must only contain one geometry type.")
  }
  layer_types_char <- sapply(layer_types,function(l) as.character(l[1]))
  if(any(layer_types_char%in%c("MULTIPOLYGON","MULTILINESTRING"))){
    stop("MULTIPOLYGONS and MULTILINESTRINGS are not supported. Use `sf::st_cast()` first.")
  }

  coords_list <- lapply(layers,function(l) sf::st_coordinates(l))
  n_pts <- c(0,cumsum(sapply(coords_list,nrow)))
  coords <- do.call("rbind",lapply(coords_list,function(xy)xy[,1:2]))
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

  for(i in 1:(length(n_pts)-1)){
    coords_list[[i]][,1:2] <- coords[(n_pts[i]+1):n_pts[i+1],]
  }

  rough_lst <- vector("list",n_layers)
  for(i in 1:n_layers){
    if(layer_types_char[i]=="POLYGON"){
      rough_lst[[i]] <- prepare_polygon(layers[[i]],coords_list[[i]])
    } else if(layer_types_char[i]=="LINESTRING"){
      rough_lst[[i]] <- prepare_linestring(layers[[i]],coords_list[[i]])
    } else if(layer_types_char[i]=="POINT"){
      rough_lst[[i]] <- prepare_points(layers[[i]],coords_list[[i]])
    }
  }

  rough_df <- do.call("rbind",rough_lst)

  if(!is.null(title)){
    title_df <- data.frame(xy="",x=width/2,y=50,shape="TITLE",color="black",
                           fill="",fillstyle="",size=NA,fillweight="",label=title,pos="c")
    rough_df <- rbind(rough_df,title_df)
  }

  if(!is.null(caption)){
    caption_df <- data.frame(xy="",x=width/2,y=height*.95,shape="CAPTION",color="black",
                           fill="",fillstyle="",size=NA,fillweight="",label=caption,pos="c")
    rough_df <- rbind(rough_df,caption_df)
  }
  rough_df$roughness <- roughness
  rough_df$bowing <- bowing
  rough_df$simplification <- simplification

  x <- list(
    data=jsonlite::toJSON(rough_df),
    font=font,
    title_font=title_font,
    caption_font=caption_font,
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

prepare_polygon <- function(object,coords){
  if(!"fill" %in% names(object)){
    object[["fill"]] <- "black"
  }

  if(!"color" %in% names(object)){
    object[["color"]] <- "black"
  }

  if(!"stroke" %in% names(object)){
    object[["stroke"]] <- 1
  }

  if(!"fillstyle" %in% names(object)){
    object[["fillstyle"]] <- "hachure"
  }

  if(!"fillweight" %in% names(object)){
    object[["fillweight"]] <- 0.5
  }
  nobj <- nrow(object)#max(coords[,4])
  mobj <- 4
  path_string <- rep("",nobj)
  coords_obj <- split(coords[,1:2],coords[,mobj])

  for(i in 1:nobj){
    xy <- matrix(coords_obj[[i]],ncol=2)
    path_string[i] <- paste0("M ",paste0(apply(xy,1,paste0,collapse=" "),collapse=" L "))
    path_string[i] <- paste0(path_string[i]," z")
  }
  data.frame(
    xy  = path_string,
    x = NA,
    y = NA,
    shape = "POLYGON",
    color = object[["color"]],
    fill  = object[["fill"]],
    fillstyle = object[["fillstyle"]],
    size = object[["stroke"]],
    fillweight = object[["fillweight"]],
    label="",
    pos="")
}

prepare_linestring <- function(object,coords){
  if(!"color" %in% names(object)){
    object[["color"]] <- "black"
  }

  if(!"stroke" %in% names(object)){
    object[["stroke"]] <- 1
  }

  nobj <- nrow(object)#max(coords[,4])
  mobj <- 3
  path_string <- rep("",nobj)
  coords_obj <- split(coords[,1:2],coords[,mobj])

  for(i in 1:nobj){
    xy <- matrix(coords_obj[[i]],ncol=2)
    path_string[i] <- paste0("M ",paste0(apply(xy,1,paste0,collapse=" "),collapse=" L "))
  }
  data.frame(
    xy  = path_string,
    x = NA,
    y = NA,
    shape = "LINESTRING",
    color = object[["color"]],
    fill  = "",
    fillstyle = "",
    size = object[["stroke"]],
    fillweight = "",
    label="",
    pos="")
}

prepare_points <- function(object,coords){
  if(!"color" %in% names(object)){
    object[["color"]] <- "black"
  }

  if(!"size" %in% names(object)){
    object[["size"]] <- 15
  }

  if(!"label" %in% names(object)){
    object[["label"]] <- ""
  }

  if(!"label_pos" %in% names(object)){
    object[["label_pos"]] <- "c"
  }

  data.frame(
    xy  = "",
    x = coords[,1],
    y = coords[,2],
    shape = "POINT",
    color = "",
    fill  = object[["color"]],
    fillstyle = "solid",
    size = object[["size"]],
    fillweight = "",
    label=object[["label"]],
    pos=object[["label_pos"]])
}

prepare_label <- function(object){

}

#<a href="https://www.freepik.com/photos/background">Background photo created by aopsan - www.freepik.com</a>
