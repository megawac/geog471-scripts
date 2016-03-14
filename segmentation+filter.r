# from http://quantitativeecology.org/using-rlidar-and-fusion-to-delineate-individual-trees-through-canopy-height-model-segmentation/

# If we want, rLiDAR can smooth the CHM using a Gaussian filter
# Set the window size (ws)
ws<-3 # dimension 3x3
# Set the filter type
filter<-"Gaussian"
# filter<-"mean"
# Set the sigma value for the Gaussian filter
sigma<-0.5
sCHM<-CHMsmoothing(chm, filter, ws, sigma)
plot(sCHM)

# Setting the fixed windo size (fws)
fws<-3 # dimention 3x3
# Set the specified height above ground for the detection break
minht<-2.0
# Create the individual tree detection list and summarize it
loc<-FindTreesCHM(sCHM, fws, minht)
summary(loc)

# Set the maxcrown parameter - maximum individual tree crown radius expected
maxcrown=10.0
# Set the exclusion parameter - A single value from 0 to 1 that represents the % of pixel
# exclusion. E.g. a value of 0.5 will exclude all of the pixels for a single tree that has
#a height value of less than 50% of the maximum height from the same tree. Default value is 0.3.
exclusion=0.1
# Compute canopy areas for the individual tree detections
canopy<-ForestCAS(sCHM, loc, maxcrown, exclusion)

# Retrieve the boundary for individual tree detection and canopy area calculation
boundaryTrees<-canopy[[1]]

# Retrieve the list of individual trees detected for canopy area calculation
canopyList<-canopy[[2]] # list of ground-projected areas of individual tree canopies
summary(canopyList)     # summary
canopyList$crad<-sqrt(canopyList$ca/pi) # Compute the corresponding crown radii

# Write the output to a CSV file. This will make bringing it into ArcGIS or QGIS by others easier
write.csv(canopyList, file.path(mainDir, outDir, "Example_Out.csv"))

# Plot the results in ggplot

# Let's convert the tree results into spatial points to be used in ggplot
library(sp)
XY<-SpatialPoints(canopyList[,1:2])    # Spatial points
XY<-data.frame(XY) # Converted to a dataframe
# We're not dealing with lat and long, so let's rename the columns
names(XY)[names(XY)=="longitude"]<-"x"
names(XY)[names(XY)=="latitude"]<-"y"

# Rasters are a little problematic, so convert the values into rows in a dataframe with
# the corresponding information
CHMdf <- rasterToPoints(sCHM); CHMdf <- data.frame(CHMdf)
colnames(CHMdf) <- c("X","Y","Ht")
# Build the breaks for plotting
b.chm <- seq(0,50,10)

# Plotting the individual tree canopy boundary over the CHM
library(ggplot2)
ggplot(CHMdf) +
  geom_raster(data=CHMdf,aes(X,Y,fill=Ht)) +
  scale_fill_gradientn(name="Canopy Height",colours = terrain.colors(length(b.chm))[length(b.chm):1],breaks=b.chm) +
  geom_polygon(data = fortify(boundaryTrees), aes(x=long, y=lat,
                                                  group = group),colour='black', fill='transparent')+
  geom_point(data=XY, aes(x=x, y=y), color="black", shape=3, size=0.5)+
  scale_shape_discrete(name = "Tree Locations", labels=c("Tree Centroid","")) +
  scale_alpha(range = c(0, 0.5)) +
  ggtitle("Location map showing individual trees and associated crown areas \n segmented from a LiDAR-derived canopy height model") +
  coord_equal() + theme_bw()
