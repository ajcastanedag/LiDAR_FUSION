# This code was created for the LiDAR curse final task to provide 3 products
# achievable based on LiDAR data. This code represents an easy way to
# understand and process pre and post-event data acquisitions to track DTM
# changes and to visualize NDSM changes to provide base data to asses damages
# caused by earthquakes. The sample data used in this code can be found in
# https://opentopography.org/ and corresponds to the Kumamoto Earthquake that
# occurred on the 16 of April of 2016. by: Antonio J. Castañeda-Gómez
##############################################################################
# load the raster, sp, and rgdal
library(raster)
library(sp)
library(rgdal)
##############################################################################
###########################  Functions  ######################################
##############################################################################
# Ground Filter (FUSION FUNCTION)
GroundFilter <- function(Output, Threshold, Input){
  GFPath <- paste0(FUSION,"\\groundfilter.exe ")
  if(file.exists(Output)){
    print("File already created...")
  } else{
  call <- paste(GFPath,"/median:4 /smooth:4 /iterations:8",
                Output,
                Threshold,
                Input,
                sep=' ')
  print("Running GroundFilter...")
  print(paste0("Input: ",Input))
  print(paste0("Output: ",Output))
  print(paste0("Threshold: ",Threshold))
  system(call,show.output.on.console = TRUE)  
  }
}
################################
# GridSurfaceCreate (FUSION FUNCTION)
GridSurfaceCreate <- function(Output, Mod, Input){
  GSCPath <- paste0(FUSION,"\\GridSurfaceCreate.exe ")
  if(file.exists(Output)){
    print("File already created...")
  } else{
  call <- paste(GSCPath,
                Output,
                Mod,
                Input,
                sep=' ')
  print("Running GridSurfaceCreate...")
  print(paste0("Input: ",Input))
  print(paste0("Output: ",Output))
  print(paste0("Mod: ", Mod))
  system(call,show.output.on.console = TRUE)  
  }
}
################################
# DTM2ASCII (FUSION FUNCTION)
Dtm2Ascii <- function(Input, Output){
  D2APath <- paste0(FUSION,"\\DTM2ASCII.exe ")
  if(file.exists(Output)){
    print("File already created...")
  } else{
  call <- paste(D2APath,
                "/raster",
                Input,
                Output,
                sep=' ')
  print("Running DTM2ASCII...")
  print(paste0("Input: ",Input))
  print(paste0("Output: ",Output))
  system(call,show.output.on.console = TRUE)  
  }
}
################################
# Ascii2Rast
Ascii2Rast <- function(Input, Output){
  RastName <- paste0(Rst,paste0("\\",Output))
  if(file.exists(RastName)){
    print("File already created...")
  } else{                   
    Raster_tmp <- raster(read.asciigrid(Input))
    crs(Raster_tmp) <- CRS('+init=EPSG:2444')
    writeRaster(Raster_tmp,RastName)
    rm(Raster_tmp)
  }
}

##############################################################################
##################  DATA LOCATION AND FOLDERS  ###############################
##############################################################################
### Choose FUSION Folder
FUSION <- choose.dir()

### Choose Main Folder
Main <- choose.dir()

### Change Directory to Main Folder
setwd(Main)

### Create SubFolders
dir.create("1.Data")
Data <- paste0(Main,"\\1.Data")
dir.create("2.DSM")
DSM <- paste0(Main,"\\2.DSM")
dir.create("3.DTM")
DTM <- paste0(Main,"\\3.DTM")
dir.create("4.Raster")
Rst <- paste0(Main,"\\4.Raster")
dir.create("5.QGis")
Qgi <- paste0(Main,"\\5.QGis")
setwd(Qgi)
dir.create("5.QGis")
dir.create("1.IMCORR_DSM")
dir.create("2.IMCORR_NDSM")

### Choose Original .las files
#-> Pre event file
Data_Pre <- choose.files()

#-> Post event file
Data_Post <- choose.files()

##############################################################################
##########################  CREATE DSM  ######################################
##############################################################################
#### Locate DSM
DSM_pre <- paste0(DSM,"\\DSM_pre.dtm")
DSM_post <- paste0(DSM,"\\DSM_post.dtm")

#### Locate ASCII data FOR DSM 
ASCII_DSM_pre <- paste0(DSM,"\\DSM_pre.asc")
ASCII_DSM_post <- paste0(DSM,"\\DSM_post.asc")

####  Grid Surface creation for DSM
GridSurfaceCreate(DSM_pre, "1 m m 0 0 0 0", Data_Pre)
GridSurfaceCreate(DSM_post, "1 m m 0 0 0 0", Data_Post)

####DSM TO ASCII
Dtm2Ascii(DSM_pre,ASCII_DSM_pre)
Dtm2Ascii(DSM_post,ASCII_DSM_post)

##############################################################################
##########################  CREATE DTM  ######################################
##############################################################################
#### Locate DTM
DTM_pre <- paste0(DTM,"\\DTM_pre.las")
DTM_post <- paste0(DTM,"\\DTM_post.las")  

#### Locate DTM Grid
DTM_pre_g <- paste0(DTM,"\\DTM_pre_g.dtm")
DTM_post_g <- paste0(DTM,"\\DTM_post_g.dtm") 

#### Locate ASCII data FOR DTM 
ASCII_DTM_pre <- paste0(DTM,"\\DTM_pre.asc")
ASCII_DTM_post <- paste0(DTM,"\\DTM_post.asc")

#### Ground Filter
GroundFilter(DTM_pre,10,Data_Pre)
GroundFilter(DTM_post,10,Data_Post)

####  Grid Surface creation for DTM
GridSurfaceCreate(DTM_pre_g, "1 m m 0 0 0 0", DTM_pre)
GridSurfaceCreate(DTM_post_g, "1 m m 0 0 0 0", DTM_post)

#### DTM TO ASCII
Dtm2Ascii(DTM_pre_g,ASCII_DTM_pre)
Dtm2Ascii(DTM_post_g,ASCII_DTM_post)

##############################################################################
#####################  CREATE RASTER FILES ###################################
##############################################################################
#### Save and project Ascii Files into GeoTiff
Ascii2Rast(ASCII_DSM_pre, "1.DSM_pre.tif")
Ascii2Rast(ASCII_DSM_post, "2.DSM_post.tif")
Ascii2Rast(ASCII_DTM_pre, "3.DTM_pre.tif")
Ascii2Rast(ASCII_DTM_post, "4.DTM_post.tif")

##############################################################################
###################  RESAMPLING RASTER FILES #################################
##############################################################################
#### setwd to Raster Folder
setwd(Rst)

#### Read GeoTiff 
DSM_pre_R <- raster("1.DSM_pre.tif")
DSM_post_R <- raster("2.DSM_post.tif")
DTM_pre_R <- raster("3.DTM_pre.tif")
DTM_post_R <- raster("4.DTM_post.tif")


##############################################################################
######################  MATCH RASTER FILES ###################################
##############################################################################
#### Create Normalized Digital Surface Model Pre-Event
DTM_pre_R_tmp <- projectRaster(DTM_pre_R, DSM_pre_R)
DTM_pre_R <- DTM_pre_R_tmp
rm(DTM_pre_R_tmp)
writeRaster(DTM_pre_R,"3.DTM_pre.tif", overwrite=TRUE)

DTM_post_R_tmp <- projectRaster(DTM_post_R, DSM_pre_R)
DTM_post_R <- DTM_post_R_tmp
rm(DTM_post_R_tmp)
writeRaster(DTM_post_R,"4.DTM_post.tif", overwrite=TRUE)

##############################################################################
#######################  NDSM CALCULATION ####################################
##############################################################################
#### Create Normalized Digital Surface Model Pre-Event
NDSM_Pre <- DSM_pre_R - DTM_pre_R
writeRaster(NDSM_Pre,'5.NDSM_Pre.tif')

#### Create Normalized Digital Surface Model Post-Event
NDSM_Post <- DSM_post_R - DTM_post_R
writeRaster(NDSM_Pre,'6.NDSM_Post.tif')

##############################################################################
#####################  NDSM DIFF CALCULATION #################################
##############################################################################
# -> BandMath
DSM_Diff <- DSM_pre_R - DSM_post_R
writeRaster(DSM_Diff,'7.DSM_Diff.tif')
##############################################################################