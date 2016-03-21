mainDir <- "Z:/"
inDir <- "QUBS_LAS/LAS"
outDir<- "QUBS_LAS/Derived"

library(rLiDAR)
library(raster)
library(rgeos)

name <- "processed1"

# Import the LiDAR-derived CHM file that we just made in the above section and plot it
chm<-raster(file.path(mainDir, outDir, paste(name, ".asc", sep="")))

png(filename=file.path(mainDir, outDir, paste(name, "-chm.png", sep="")))
plot(chm)
dev.off()
