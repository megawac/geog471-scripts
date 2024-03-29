# Adapted from http://quantitativeecology.org/using-rlidar-and-fusion-to-delineate-individual-trees-through-canopy-height-model-segmentation/
# expects that we're using our 471 structure and that the group folder is configured as
# the Z:/ drive on the local machine
# places all the canopy height models in the QUBS_LAS/Derived folder along with corresponding
# assets used to derive the model.

# First things first, we need to set up some directories to keep the raw data
# separate from that produced by the analysis. I basically have an input (.las)
# and output (.las, .dtm, etc) directory in a dropbox folder.
mainDir <- file.path("F:", "Users", "Dynomite", "471", "QUBS_LAS")
inDir <- file.path(mainDir, "LAS3")
outDir<- file.path(mainDir, "Derived")
fusionPath <- file.path("C:","Fusion")
dir.create(outDir)

# Concat strings helper
p <- function(..., sep='') {
  paste(..., sep=sep, collapse=sep)
}

name <- 'processed3'# strsplit(image, '[.]')[[1]][1]
res <- 1

images <- list.files(inDir, pattern="*.las")
imagePaths <- sapply(images, function(i) {
  file.path(inDir, i)
})
allImageString <- paste(imagePaths, collapse=' ')


# Read in the .las file and use FUSION to produce a .las file of points that
# approximate the ground's surface (bare-earth points).
# http://forsys.cfr.washington.edu/fusion/FUSION_manual.pdf#page=94&zoom=auto,70,720
if (!file.exists(file.path(outDir, p(name, "-ground-points.las")))) {
  system(paste(file.path(fusionPath, "groundfilter.exe"),
         "/gparam:0 /wparam:1 /tolerance:1 /iterations:10",
         file.path(outDir, p(name, "-ground-points.las")),
         res, #grid size in meters
         allImageString,
         sep=" "))
} else {
  print("skipping groundfilter")
}

# Next we use gridSurfaceCreate to compute the elevation of each grid cell using the
# average elevation of all points within the cell. Check the manual for arguments and uasge
# http://forsys.cfr.washington.edu/fusion/FUSION_manual.pdf#page=88&zoom=auto,70,720
if (!file.exists(file.path(outDir, p(name, "-surface", ".dtm")))) {
  system(paste(file.path(fusionPath, "gridsurfacecreate.exe"),
         file.path(outDir, p(name, "-surface", ".dtm")),
         p(res, " M M 1 12 2 2"),
         file.path(outDir, p(name, "-ground-points.las")),
         sep=" "))
} else {
  print("skipping groundsurface")
}

# Next we use CanopyModel to create a canopy surface model using a LIDAR point cloud.
# By default, the algorithm used by CanopyModel assigns the elevation of the highest return within
# each grid cell to the grid cell center.
#http://forsys.cfr.washington.edu/fusion/FUSION_manual.pdf#page=32&zoom=auto,70,720
if (!file.exists(file.path(outDir, p(name, "-final", ".dtm")))) {
  system(paste(file.path(fusionPath, "canopymodel.exe"),
         p("/ground:", file.path(outDir, p(name, "-surface", ".dtm"))),
         file.path(outDir, p(name, "-final", ".dtm")),
         p(res, " M M 1 12 2 2"),
         allImageString,
         sep=" "))
}  else {
  print("skipping canopymodel")
}

# Lastly, we use DTM2ASCII to convert the data stored in the PLANS DTM format into ASCII raster
# an file. Such files can be imported into GIS software such as ArcGIS or QGIS.
# http://forsys.cfr.washington.edu/fusion/FUSION_manual.pdf#page=88&zoom=auto,70,720
if (!file.exists(file.path(outDir, p(name, ".asc")))) {
  system(paste(file.path(fusionPath, "dtm2ascii.exe"),
         file.path(outDir, p(name, "-final", ".dtm")),
         file.path(outDir, p(name, ".asc")),
         sep=" "))
} else {
  print("skipping ascii")
}

# Second, we process the resulting CHM in rLiDAR


#install.packages("rLiDAR", type="source")
#install.packages("raster", dependencies = TRUE)
library(rLiDAR)
library(raster)
library(rgeos)
#
# # Import the LiDAR-derived CHM file that we just made in the above section and plot it
# chm<-raster(file.path(outDir, p(name, ".asc")))
# #
# png(filename=file.path(mainDir, outDir, p(name, "-chm.png")))
# plot(chm)
# dev.off()
