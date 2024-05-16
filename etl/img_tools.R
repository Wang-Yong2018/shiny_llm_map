box::use(magick[image_info, 
                image_read, image_write,
                image_resize])



resize_image <- function(img_path,max_width=400,max_height=300) {
  # resize he image to max_width* max_height size 
  # load image
  img_content <- image_read(img_path)
  # Read image info
  info <- image_info(img_content)
  
  # Calculate scaling factor (if needed)
  scale_factor <- ifelse(max(info$width, info$height) > max_width,
                         min(max_width / info$width, max_width / info$height),
                         1)
  
  # Generate resized image (if scaling needed)
  if (scale_factor != 1) {
    # Use appropriate library (e.g., magick, jpeg) for resizing
    resized_img_content <- 
      img_content |>
      image_resize(scale_factor * info$width)
    
    result <- list(src = resized_img_content, 
                   contentType = 'image/jpep', # Adjust based on image format
                   width = paste0(scale_factor * info$width, "px"),
                   height = paste0(scale_factor * info$height, "px"),
                   alt = "This is an resized image")
  } else {
    # Return original image details if no scaling needed
    result<- list(src = img_content, 
                  contentType = 'image/jpep', # Adjust based on image format 
                  width = paste0(info$width,'px'),
                  height = paste0(info$height,'px'),
                  alt = "This is an original image")
  }
  tmpfile <- result$src |> image_write(tempfile(fileext='jpg'), format = 'jpg')
  return(tmpfile)
}