mainDir <- "Z:/"
inDir <- "QUBS_LAS/LAS"
outDir<- "QUBS_LAS/Derived"

library(rLiDAR)
library(raster)
library(rgeos)

# Import the LiDAR-derived CHM file that we just made in the above section and plot it
chm<-raster(file.path(mainDir, outDir, "3864927.asc"))

png(filename=file.path(mainDir, outDir, "3864927-chm.png"))
plot(chm)
dev.off()
