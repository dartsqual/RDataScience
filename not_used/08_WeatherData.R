#' ---
#' title: "Climate Metrics from daily weather data"
#' ---
#' 
#' 
#' [<i class="fa fa-file-code-o fa-3x" aria-hidden="true"></i> The R Script associated with this page is available here](`r output`).  Download this file and open it (or copy-paste into a new script) with RStudio so you can follow along.  
#' 
#' # Summary
#' 
#' * Access and work with station weather data from Global Historical Climate Network (GHCN)  
#' * Explore options for plotting timeseries
#' * Trend analysis
#' * Compute Climate Extremes
#' 
#' # Climate Metrics
#' 
#' ## Climate Metrics: ClimdEX
#' Indices representing extreme aspects of climate derived from daily data:
#' 
#' <img src="08_assets/climdex.png" alt="alt text" width="50%">
#' 
#' Climate Change Research Centre (CCRC) at University of New South Wales (UNSW) ([climdex.org](http://www.climdex.org)).  
#' 
#' ### 27 Core indices
#' 
#' For example:
#' 
#' * **FD** Number of frost days: Annual count of days when TN (daily minimum temperature) < 0C.
#' * **SU** Number of summer days: Annual count of days when TX (daily maximum temperature) > 25C.
#' * **ID** Number of icing days: Annual count of days when TX (daily maximum temperature) < 0C.
#' * **TR** Number of tropical nights: Annual count of days when TN (daily minimum temperature) > 20C.
#' * **GSL** Growing season length: Annual (1st Jan to 31st Dec in Northern Hemisphere (NH), 1st July to 30th June in Southern Hemisphere (SH)) count between first span of at least 6 days with daily mean temperature TG>5C and first span after July 1st (Jan 1st in SH) of 6 days with TG<5C.
#' * **TXx** Monthly maximum value of daily maximum temperature
#' * **TN10p** Percentage of days when TN < 10th percentile
#' * **Rx5day** Monthly maximum consecutive 5-day precipitation
#' * **SDII** Simple pricipitation intensity index
#' 
#' 
#' # Weather Data
#' 
#' ### Climate Data Online
#' 
#' ![CDO](08_assets/climatedataonline.png)
#' 
#' ### GHCN 
#' 
#' ![ghcn](08_assets/ghcn.png)
#' 
#' ## Options for downloading data
#' 
#' ### `FedData` package
#' 
#' * National Elevation Dataset digital elevation models (1 and 1/3 arc-second; USGS)
#' * National Hydrography Dataset (USGS)
#' * Soil Survey Geographic (SSURGO) database 
#' * International Tree Ring Data Bank.
#' * *Global Historical Climatology Network* (GHCN)
#' 
#' ### NOAA API
#' 
#' ![noaa api](08_assets/noaa_api.png)
#' 
#' [National Climatic Data Center application programming interface (API)]( http://www.ncdc.noaa.gov/cdo-web/webservices/v2). 
#' 
#' ### `rNOAA` package
#' 
#' Handles downloading data directly from NOAA APIv2.
#' 
#' * `buoy_*`  NOAA Buoy data from the National Buoy Data Center
#' * `ghcnd_*`  GHCND daily data from NOAA
#' * `isd_*` ISD/ISH data from NOAA
#' * `homr_*` Historical Observing Metadata Repository
#' * `ncdc_*` NOAA National Climatic Data Center (NCDC)
#' * `seaice` Sea ice
#' * `storm_` Storms (IBTrACS)
#' * `swdi` Severe Weather Data Inventory (SWDI)
#' * `tornadoes` From the NOAA Storm Prediction Center
#' 
#' ---
#' 
#' ### Libraries
#' 
## ----results='hide',message=FALSE----------------------------------------
library(raster)
library(sp)
library(rgdal)
library(ggplot2)
library(ggmap)
library(dplyr)
library(tidyr)
library(maps)
# New Packages
library(rnoaa)
library(climdex.pcic)
library(zoo)
library(reshape2)

#' 
#' ### Station locations 
#' 
#' Download the GHCN station inventory with `ghcnd_stations()`.  
#' 
## ------------------------------------------------------------------------
datadir="data"

st = ghcnd_stations()

## Optionally, save it to disk
# write.csv(st,file.path(datadir,"st.csv"))
## If internet fails, load the file from disk using:
# st=read.csv(file.path(datadir,"st.csv"))

#' 
#' ### GHCND Variables
#' 
#' 5 core values:
#' 
#' * **PRCP** Precipitation (tenths of mm)
#' * **SNOW** Snowfall (mm)
#' * **SNWD** Snow depth (mm)
#' * **TMAX** Maximum temperature
#' * **TMIN** Minimum temperature
#' 
#' And ~50 others!  For example:
#' 
#' * **ACMC** Average cloudiness midnight to midnight from 30-second ceilometer 
#' * **AWND** Average daily wind speed
#' * **FMTM** Time of fastest mile or fastest 1-minute wind
#' * **MDSF** Multiday snowfall total
#' 
#' 
#' ### `filter()` to temperature and precipitation
## ------------------------------------------------------------------------
st=dplyr::filter(st,element%in%c("TMAX","TMIN","PRCP"))

#' 
#' ### Map GHCND stations
#' 
#' First, get a global country polygon
## ---- warning=F----------------------------------------------------------
worldmap=map_data("world")

#' 
#' Plot all stations:
## ------------------------------------------------------------------------
ggplot(data=st,aes(y=latitude,x=longitude)) +
  annotation_map(map=worldmap,size=.1,fill="grey",colour="black")+
  geom_point(size=.1,col="red")+
  facet_grid(element~1)+
  coord_equal()

#' 
#' It's hard to see all the points, let's bin them...
#' 
## ------------------------------------------------------------------------
ggplot(st,aes(y=latitude,x=longitude)) +
  annotation_map(map=worldmap,size=.1,fill="grey",colour="black")+
  facet_grid(element~1)+
  stat_bin2d(bins=100)+
  scale_fill_distiller(palette="YlOrRd",trans="log",direction=-1,
                       breaks = c(1,10,100,1000))+
  coord_equal()

#' <div class="well">
#' ## Your turn
#' 
#' Produce a binned map (like above) with the following modifications:
#' 
#' * include only stations with data between 1950 and 2000
#' * include only `tmax`
#' 
#' <button data-toggle="collapse" class="btn btn-primary btn-sm round" data-target="#demo1">Show Solution</button>
#' <div id="demo1" class="collapse">
#' 
#' </div>
#' </div>
#' 
#' ## Download daily data from GHCN
#' 
#' `ghcnd()` will download a `.dly` file for a particular station.  But how to choose?
#' 
#' ### `geocode` in ggmap package useful for geocoding place names 
#' Geocodes a location (find latitude and longitude) using either (1) the Data Science Toolkit (http://www.datasciencetoolkit.org/about) or (2) Google Maps. 
#' 
## ------------------------------------------------------------------------
geocode("University at Buffalo, NY")

#' 
#' However, you have to be careful:
## ------------------------------------------------------------------------
geocode("My Grandma's house")

#' 
#' But this is pretty safe for well known places.
## ------------------------------------------------------------------------
coords=as.matrix(geocode("Buffalo, NY"))
coords

#' 
#' Now use that location to spatially filter stations with a rectangular box.
## ------------------------------------------------------------------------
dplyr::filter(st,
              grepl("BUFFALO",name)&
              between(latitude,coords[2]-1,coords[2]+1) &
              between(longitude,coords[1]-1,coords[1]+1)&
         element=="TMAX")

#' You could also spatially filter using `over()` in sp package...
#' 
#' 
#' With the station ID, we can now download daily data from NOAA.
## ------------------------------------------------------------------------
d=meteo_tidy_ghcnd("USW00014733",
                   var = c("TMAX","TMIN","PRCP"),
                   keep_flags=T)
head(d)

#' 
#' See [CDO Daily Description](http://www1.ncdc.noaa.gov/pub/data/cdo/documentation/GHCND_documentation.pdf) and raw [GHCND metadata](http://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt) for more details.  If you want to download multiple stations at once, check out `meteo_pull_monitors()`
#' 
#' ### Quality Control: MFLAG
#' 
#' Measurement Flag/Attribute
#' 
#' * **Blank** no measurement information applicable
#' * **B** precipitation total formed from two twelve-hour totals
#' * **H** represents highest or lowest hourly temperature (TMAX or TMIN) or average of hourly values (TAVG)
#' * **K** converted from knots
#' * ...
#' 
#' See [CDO Description](http://www1.ncdc.noaa.gov/pub/data/cdo/documentation/GHCND_documentation.pdf) 
#' 
#' ### Quality Control: QFLAG
#' 
#' * **Blank** did not fail any quality assurance check 
#' * **D** failed duplicate check
#' * **G** failed gap check
#' * **K** failed streak/frequent-value check
#' * **N** failed naught check
#' * **O** failed climatological outlier check
#' * **S** failed spatial consistency check
#' * **T** failed temporal consistency check
#' * **W** temperature too warm for snow
#' * ...
#' 
#' See [CDO Description](http://www1.ncdc.noaa.gov/pub/data/cdo/documentation/GHCND_documentation.pdf) 
#' 
#' ### Quality Control: SFLAG
#' 
#' Indicates the source of the data...
#' 
#' ## Summarize QC flags
#' 
#' Summarize the QC flags.  How many of which type are there?  Should we be more conservative?
#' 
## ------------------------------------------------------------------------
table(d$qflag_tmax)  
table(d$qflag_tmin)  
table(d$qflag_prcp)  

#' * **T** failed temporal consistency check
#' 
#' #### Filter with QC data and change units
## ------------------------------------------------------------------------
d_filtered=d%>%
  mutate(tmax=ifelse(qflag_tmax!=" "|tmax==-9999,NA,tmax/10))%>%  # convert to degrees C
  mutate(tmin=ifelse(qflag_tmin!=" "|tmin==-9999,NA,tmin/10))%>%  # convert to degrees C
  mutate(prcp=ifelse(qflag_tmin!=" "|prcp==-9999,NA,prcp))%>%  # convert to degrees C
  arrange(date)

#' 
#' Plot temperatures
## ------------------------------------------------------------------------
ggplot(d_filtered,
       aes(y=tmax,x=date))+
  geom_line(col="red")

#' 
#' Limit to a few years and plot the daily range and average temperatures.
## ------------------------------------------------------------------------
d_filtered_recent=filter(d_filtered,date>as.Date("2013-01-01"))

  ggplot(d_filtered_recent,
         aes(ymax=tmax,ymin=tmin,x=date))+
    geom_ribbon(col="grey",fill="grey")+
    geom_line(aes(y=(tmax+tmin)/2),col="red")

#' 
#' ### Zoo package for rolling functions
#' 
#' Infrastructure for Regular and Irregular Time Series (Z's Ordered Observations)
#' 
#' * `rollmean()`:  Rolling mean
#' * `rollsum()`:   Rolling sum
#' * `rollapply()`:  Custom functions
#' 
#' Use rollmean to calculate a rolling 60-day average. 
#' 
#' * `align` whether the index of the result should be left- or right-aligned or centered
#' 
## ------------------------------------------------------------------------
d_rollmean = d_filtered_recent %>% 
  arrange(date) %>%
  mutate(tmax.60 = rollmean(x = tmax, 60, align = "center", fill = NA),
         tmax.b60 = rollmean(x = tmax, 60, align = "right", fill = NA))

#' 
## ------------------------------------------------------------------------
d_rollmean%>%
  ggplot(aes(ymax=tmax,ymin=tmin,x=date))+
    geom_ribbon(fill="grey")+
    geom_line(aes(y=(tmin+tmax)/2),col=grey(0.4),size=.5)+
    geom_line(aes(y=tmax.60),col="red")+
    geom_line(aes(y=tmax.b60),col="darkred")

#' 
#' <div class="well">
#' ## Your Turn
#' 
#' Plot a 30-day rolling "right" aligned sum of precipitation.
#' 
#' <button data-toggle="collapse" class="btn btn-primary btn-sm round" data-target="#demo2">Show Solution</button>
#' <div id="demo2" class="collapse">
#' </div>
#' </div>
#' 
#' 
#' # Time Series analysis
#' 
#' Most timeseries functions use the time series class (`ts`)
#' 
## ------------------------------------------------------------------------
tmin.ts=ts(d_filtered_recent$tmin,frequency = 365)

#' 
#' ## Temporal autocorrelation
#' 
#' Values are highly correlated!
#' 
## ------------------------------------------------------------------------
ggplot(d_filtered_recent,aes(y=tmin,x=lag(tmin)))+
  geom_point()+
  geom_abline(intercept=0, slope=1)

#' 
#' ### Autocorrelation functions
#' 
#' * autocorrelation  $x$ vs. $x_{t-1}$  (lag=1)
#' * partial autocorrelation.  $x$  vs. $x_{n}$ _after_ controlling for correlations $\in t-1:n$
#' 
#' #### Autocorrelation
## ------------------------------------------------------------------------
acf(tmin.ts,lag.max = 365*3,na.action = na.exclude )

#' 
#' #### Partial Autocorrelation
## ------------------------------------------------------------------------
pacf(tmin.ts,lag.max = 365*3,na.action = na.exclude )

#' 
#' 
#' # Checking for significant trends
#' 
#' ## Compute temporal aggregation indices
#' 
#' ### Group by month, season, year, and decade.
#' 
#' How to convert years into 'decades'?
## ------------------------------------------------------------------------
1938
round(1938,-1)
floor(1938/10)*10

#' 
#' 
## ------------------------------------------------------------------------
d_filtered2=d_filtered%>%
  mutate(month=as.numeric(format(date,"%m")),
        year=as.numeric(format(date,"%Y")),
        season=ifelse(month%in%c(12,1,2),"Winter",
            ifelse(month%in%c(3,4,5),"Spring",
              ifelse(month%in%c(6,7,8),"Summer",
                ifelse(month%in%c(9,10,11),"Fall",NA)))),
        dec=(floor(as.numeric(format(date,"%Y"))/10)*10))
head(d_filtered2)

#' 
#' ## Timeseries models
#' 
#' 
#' How to assess change? Simple differences?
#' 
## ------------------------------------------------------------------------
d_filtered2%>%
  mutate(period=ifelse(year<=1976-01-01,"early","late"))%>%
  group_by(period)%>%
  summarize(n=n(),
            tmin=mean(tmin,na.rm=T),
            tmax=mean(tmax,na.rm=T),
            prcp=mean(prcp,na.rm=T))

#' 
#' #### Summarize by season
## ------------------------------------------------------------------------
seasonal=d_filtered2%>%
  group_by(year,season)%>%
  summarize(n=n(),
            tmin=mean(tmin),
            tmax=mean(tmax),
            prcp=mean(prcp))%>%
  filter(n>75)

ggplot(seasonal,aes(y=tmin,x=year))+
  facet_wrap(~season,scales = "free_y")+
  stat_smooth(method="lm", se=T)+
  geom_line()

#' 
#' ### Kendal Seasonal Trend Test
#' 
#' Nonparametric seasonal trend analysis. 
#' 
#' e.g. [Hirsch-Slack test](http://onlinelibrary.wiley.com/doi/10.1029/WR020i006p00727)
#' 
## ------------------------------------------------------------------------
library(EnvStats)
t1=kendallSeasonalTrendTest(tmax~season+year,data=seasonal)
t1

#' 
#' #### Minimum Temperature
## ------------------------------------------------------------------------
t2=kendallSeasonalTrendTest(tmin~season+year,data=seasonal)
t2

#' 
#' ### Autoregressive models
#' See [Time Series Analysis Task View](https://cran.r-project.org/web/views/TimeSeries.html) for summary of available packages/models. 
#' 
#' * Moving average (MA) models
#' * autoregressive (AR) models
#' * autoregressive moving average (ARMA) models
#' * frequency analysis
#' * Many, many more...
#' 
#' -------
#' 
#' # Climate Metrics
#' 
#' ### Climdex indices
#' [ClimDex](http://www.climdex.org/indices.html)
#' 
#' ###  Format data for `climdex`
#' 
## ------------------------------------------------------------------------
library(PCICt)
## Parse the dates into PCICt.
pc.dates <- as.PCICt(as.POSIXct(d_filtered$date),cal="gregorian")

#' 
#' 
#' ### Generate the climdex object
## ------------------------------------------------------------------------
  library(climdex.pcic)
    ci <- climdexInput.raw(
      tmax=d_filtered$tmax,
      tmin=d_filtered$tmin,
      prec=d_filtered$prcp,
      pc.dates,pc.dates,pc.dates, 
      base.range=c(1971, 2000))
years=as.numeric(as.character(unique(ci@date.factors$annual)))

#' 
#' ### Cumulative dry days
#' 
## ------------------------------------------------------------------------
cdd= climdex.cdd(ci, spells.can.span.years = TRUE)
plot(cdd~years,type="l")

#' 
#' ### Diurnal Temperature Range
#' 
## ------------------------------------------------------------------------
dtr=climdex.dtr(ci, freq = c("annual"))
plot(dtr~years,type="l")

#' 
#' ### Frost Days
#' 
## ------------------------------------------------------------------------
fd=climdex.fd(ci)
plot(fd~years,type="l")

#' 
#' <div class="well">
#' ## Your Turn
#' 
#' See all available indices with:
## ------------------------------------------------------------------------
climdex.get.available.indices(ci)

#' 
#' Select 3 indices, calculate them, and plot the timeseries.
#' 
#' <button data-toggle="collapse" class="btn btn-primary btn-sm round" data-target="#demo4">Show Solution</button>
#' <div id="demo4" class="collapse">
#' 
#' 
#' </div>
#' </div>
#' 
#' 
#' 
