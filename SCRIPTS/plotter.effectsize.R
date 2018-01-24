#!/usr/local/bin/Rscript --vanilla

### Mac OS X version
### #!/usr/local/bin/Rscript --vanilla

### Linux version
### #!/hpc/local/CentOS7/dhl_ec/software/R-3.4.0/bin/Rscript --vanilla

cat("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Effect Size Plotter -- GWASToolKit
    \n
    * Version: v1.3.6
    * Last edit: 2018-01-24
    * Created by: Sander W. van der Laan | s.w.vanderlaan@gmail.com
    \n
    * Description:  EffectSize-plotter for GWAS (meta-analysis) results. Can produce output 
    in different colours and image-formats. One column is expected with the
    effect size (beta) and NO HEADER! It will produce a histogram of the 'beta'±4*SD.
    The script should be usuable on both any Linux distribution with R 3+ installed, Mac OS X and Windows.
    
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")

# usage: ./effectsize_plotter.R -p projectdir -r resultfile -o outputdir -f imageformat [OPTIONAL: -v verbose (DEFAULT) -q quiet]
#        ./effectsize_plotter.R --projectdir projectdir --resultfile resultfile --outputdir outputdir --imageformat imageformat [OPTIONAL: --verbose verbose (DEFAULT) -quiet quiet]

cat("\n* Clearing the environment...\n\n")
#--------------------------------------------------------------------------
### CLEAR THE BOARD
rm(list=ls())

cat("\n* Loading function to install packages...\n\n")
### Prerequisite: 'optparse'-library
### * Manual: http://cran.r-project.org/web/packages/optparse/optparse.pdf
### * Vignette: http://www.icesi.edu.co/CRAN/web/packages/optparse/vignettes/optparse.pdf

### Don't say "Loading required package: optparse"...
###suppressPackageStartupMessages(require(optparse))
###require(optparse)

### The part of installing (and loading) packages via Rscript doesn't properly work.
### FUNCTION TO INSTALL PACKAGES
install.packages.auto <- function(x) { 
  x <- as.character(substitute(x)) 
  if(isTRUE(x %in% .packages(all.available = TRUE))) { 
    eval(parse(text = sprintf("require(\"%s\")", x)))
  } else { 
    # Update installed packages - this may mean a full upgrade of R, which in turn
    # may not be warrented. 
    #update.packages(ask = FALSE) 
    eval(parse(text = sprintf("install.packages(\"%s\", dependencies = TRUE, repos = \"http://cran-mirror.cs.uu.nl/\")", x)))
  }
  if(isTRUE(x %in% .packages(all.available = TRUE))) { 
    eval(parse(text = sprintf("require(\"%s\")", x)))
  } else {
    source("http://bioconductor.org/biocLite.R")
    # Update installed packages - this may mean a full upgrade of R, which in turn
    # may not be warrented.
    #biocLite(character(), ask = FALSE) 
    eval(parse(text = sprintf("biocLite(\"%s\")", x)))
    eval(parse(text = sprintf("require(\"%s\")", x)))
  }
}

cat("\n* Checking availability of required packages and installing if needed...\n\n")
### INSTALL PACKAGES WE NEED
install.packages.auto("optparse")
install.packages.auto("tools")
install.packages.auto("dplyr")
install.packages.auto("tidyr")
install.packages.auto("data.table")

cat("\nDone! Required packages installed and loaded.\n\n")

cat("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
uithof_color=c("#FBB820","#F59D10","#E55738","#DB003F","#E35493","#D5267B",
               "#CC0071","#A8448A","#9A3480","#8D5B9A","#705296","#686AA9",
               "#6173AD","#4C81BF","#2F8BC9","#1290D9","#1396D8","#15A6C1",
               "#5EB17F","#86B833","#C5D220","#9FC228","#78B113","#49A01D",
               "#595A5C","#A2A3A4", "#D7D8D7", "#ECECEC", "#FFFFFF", "#000000")

#--------------------------------------------------------------------------
### OPTION LISTING
option_list = list(
  make_option(c("-p", "--projectdir"), action="store", default=NA, type='character',
              help="Path to the project directory."),
  make_option(c("-r", "--resultfile"), action="store", default=NA, type='character',
              help="Path to the results directory, relative to the project directory."),
  make_option(c("-f", "--imageformat"), action="store", default=NA, type='character',
              help="The image format (PDF (width=10, height=10), PNG/TIFF/EPS (width=800, height=800)."),
  make_option(c("-o", "--outputdir"), action="store", default=NA, type='character',
              help="Path to the output directory."),
  make_option(c("-v", "--verbose"), action="store_true", default=TRUE,
              help="Should the program print extra stuff out? [default %default]"),
  make_option(c("-q", "--quiet"), action="store_false", dest="verbose",
              help="Make the program not be verbose.")
  #make_option(c("-c", "--cvar"), action="store", default="this is c",
  #            help="a variable named c, with a default [default %default]")  
)
opt = parse_args(OptionParser(option_list=option_list))

#--------------------------------------------------------------------------
### FOR LOCAL DEBUGGING
# opt$projectdir="/Volumes/MyBookStudioII/Backup/PLINK/analyses/meta_gwasfabp4/METAFABP4_1000G/RAW/EPICNL_m1"
# opt$outputdir="/Volumes/MyBookStudioII/Backup/PLINK/analyses/meta_gwasfabp4/METAFABP4_1000G/RAW/EPICNL_m1"
# opt$imageformat="PNG"
# opt$resultfile="/Volumes/MyBookStudioII/Backup/PLINK/analyses/meta_gwasfabp4/METAFABP4_1000G/RAW/EPICNL_m1/EPICNL_m1.RAW.HISTOGRAM_BETA.txt"

if (opt$verbose) {
  ### You can use either the long or short name; so opt$a and opt$avar are the same.
  ### Show the user what the variables are.
  cat("\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
  cat("Checking the settings.")
  cat("\nThe project directory....................: ")
  cat(opt$projectdir)
  cat("\nThe results file.........................: ")
  cat(opt$resultfile)
  cat("\nThe output directory.....................: ")
  cat(opt$outputdir)
  cat("\nThe color style..........................: ")
  cat(opt$imageformat)
  cat("\n\n")
  
}
cat("\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
cat("Wow. We are finally starting \"Effect Size Plotter\". ")
#--------------------------------------------------------------------------
### START OF THE PROGRAM
# main point of program is here, do this whether or not "verbose" is set
if(!is.na(opt$projectdir) & !is.na(opt$resultfile) & !is.na(opt$outputdir) & !is.na(opt$imageformat)) {
  ### set studyname
  study <- file_path_sans_ext(basename(opt$resultfile)) # argument 2
  cat(paste("We are going to \nmake Effect Size plot of your (meta-)GWAS results. \nData are taken from.....: '",study,"'\nand will be outputed in.....: '", opt$outputdir, "'.\n",sep=''))
  cat("\n\n")
  
  #--------------------------------------------------------------------------
  ### GENERAL SETUP
  Today=format(as.Date(as.POSIXlt(Sys.time())), "%Y%m%d")
  cat(paste("Today's date is: ", Today, ".\n", sep = ''))
  
  #--------------------------------------------------------------------------
  ### DEFINE THE LOCATIONS OF DATA
  ROOT_loc = opt$projectdir # argument 1
  OUT_loc = opt$outputdir # argument 4
  
  #--------------------------------------------------------------------------
  ### LOADING RESULTS FILE
  ### Location of is set by 'opt$resultfile' # argument 2
  cat("Loading results file and removing NA's...")

  ### Checking file type -- is it gzipped or not?
  data_connection <- file(opt$resultfile)
  data_connection
  filetype <- summary(data_connection)$class
  filetype
  close(data_connection)
 
  ### Loading the data
  if(filetype == "gzfile"){
  cat("\n* The file appears to be gzipped, now loading...")
    rawdata = fread(paste0("zcat < ",opt$resultfile), header = FALSE, blank.lines.skip = TRUE)
  } else if(filetype != "gzfile") {
  cat("\n* The file appears not to be gzipped, now loading...")
    rawdata = fread(opt$resultfile, header = FALSE, blank.lines.skip = TRUE)
  } else {
  cat ("\n\n*** ERROR *** Something is rotten in the City of Gotham. We can't determine the file type 
of the data. Double back, please.\n\n", 
         file=stderr()) # print error messages to stder
  }
  cat("\n* Removing NA's...")
  data <- na.omit(rawdata)
  
  cat("\nCalculating mean and ± 4 s.d. ...")
  meanBETA=mean(data$V1)
  meanBETA_min4SD=meanBETA-(4*sd(data$V1))
  meanBETA_plus4SD=meanBETA+(4*sd(data$V1))
    
  #--------------------------------------------------------------------------
  ### PLOT INFO-SCORE PLOT
  cat("\n\nDetermining what type of image should be produced...")
  if (opt$imageformat == "PNG") 
    png(paste0(opt$outputdir,"/",study,".png"), width = 800, height = 800)
  
  if (opt$imageformat == "TIFF") 
    tiff(paste0(opt$outputdir,"/",study,".tiff"), width = 800, height = 800)
  
  if (opt$imageformat == "EPS") 
    postscript(file = paste0(opt$outputdir,"/",study,".eps"), horizontal = FALSE, onefile = FALSE, paper = "special")
  
  if (opt$imageformat == "PDF") 
    pdf(paste0(opt$outputdir,"/",study,".pdf"), width = 10, height = 10)
  
  #--------------------------------------------------------------------------
  ### START PLOTTING  
  cat("\n\nPlotting...")
  hist(data$V1, main = expression(paste("Effect size, ", beta)), 
       xlab = expression(beta), breaks = 100, col = uithof_color[8])
  abline(v = meanBETA, lty = 1, lwd = 1, col = uithof_color[25])
  abline(v = meanBETA_min4SD, lty = 2, lwd = 1, col = uithof_color[25])
  abline(v = meanBETA_plus4SD, lty = 2, lwd = 1, col = uithof_color[25])
  
  dev.off()
  
} else {
  cat("\n\n\n\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
  cat("\n*** ERROR *** You didn't specify all variables:\n
      - --p/projectdir  : path to project directory\n
      - --r/resultfile  : path to resultfile\n
      - --o/outputdir   : path to output directory\n
      - --f/imageformat : the image format (PDF, PNG, TIFF or PostScript)\n\n", 
      file=stderr()) # print error messages to stderr
}

#--------------------------------------------------------------------------
### CLOSING MESSAGE
cat(paste("\n\nAll done making the Effect Size plot of",study,".\n"))
cat(paste("\nToday's: ",Today, "\n"))
cat("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")

#--------------------------------------------------------------------------
#
# ### SAVE ENVIRONMENT | FOR DEBUGGING
# save.image(paste0(opt$outputdir,"/",Today,"_",study,"_DEBUG_EFFECTSIZE_PLOTTER.RData"))

###	UtrechtSciencePark Colours Scheme
###
### Website to convert HEX to RGB: http://hex.colorrrs.com.
### For some functions you should divide these numbers by 255.
###
###	No.	Color				HEX		RGB							CMYK					CHR		MAF/INFO
### --------------------------------------------------------------------------------------------------------------------
###	1	yellow				#FBB820 (251,184,32)				(0,26.69,87.25,1.57) 	=>	1 		or 1.0 > INFO
###	2	gold				#F59D10 (245,157,16)				(0,35.92,93.47,3.92) 	=>	2		
###	3	salmon				#E55738 (229,87,56) 				(0,62.01,75.55,10.2) 	=>	3 		or 0.05 < MAF < 0.2 or 0.4 < INFO < 0.6
###	4	darkpink			#DB003F ((219,0,63)					(0,100,71.23,14.12) 	=>	4		
###	5	lightpink			#E35493 (227,84,147)				(0,63,35.24,10.98) 		=>	5 		or 0.8 < INFO < 1.0
###	6	pink				#D5267B (213,38,123)				(0,82.16,42.25,16.47) 	=>	6		
###	7	hardpink			#CC0071 (204,0,113)					(0,0,0,0) 	=>	7		
###	8	lightpurple			#A8448A (168,68,138)				(0,0,0,0) 	=>	8		
###	9	purple				#9A3480 (154,52,128)				(0,0,0,0) 	=>	9		
###	10	lavendel			#8D5B9A (141,91,154)				(0,0,0,0) 	=>	10		
###	11	bluepurple			#705296 (112,82,150)				(0,0,0,0) 	=>	11		
###	12	purpleblue			#686AA9 (104,106,169)				(0,0,0,0) 	=>	12		
###	13	lightpurpleblue		#6173AD (97,115,173/101,120,180)	(0,0,0,0) 	=>	13		
###	14	seablue				#4C81BF (76,129,191)				(0,0,0,0) 	=>	14		
###	15	skyblue				#2F8BC9 (47,139,201)				(0,0,0,0) 	=>	15		
###	16	azurblue			#1290D9 (18,144,217)				(0,0,0,0) 	=>	16		 or 0.01 < MAF < 0.05 or 0.2 < INFO < 0.4
###	17	lightazurblue		#1396D8 (19,150,216)				(0,0,0,0) 	=>	17		
###	18	greenblue			#15A6C1 (21,166,193)				(0,0,0,0) 	=>	18		
###	19	seaweedgreen		#5EB17F (94,177,127)				(0,0,0,0) 	=>	19		
###	20	yellowgreen			#86B833 (134,184,51)				(0,0,0,0) 	=>	20		
###	21	lightmossgreen		#C5D220 (197,210,32)				(0,0,0,0) 	=>	21		
###	22	mossgreen			#9FC228 (159,194,40)				(0,0,0,0) 	=>	22		or MAF > 0.20 or 0.6 < INFO < 0.8
###	23	lightgreen			#78B113 (120,177,19)				(0,0,0,0) 	=>	23/X
###	24	green				#49A01D (73,160,29)					(0,0,0,0) 	=>	24/Y
###	25	grey				#595A5C (89,90,92)					(0,0,0,0) 	=>	25/XY	or MAF < 0.01 or 0.0 < INFO < 0.2
###	26	lightgrey			#A2A3A4	(162,163,164)				(0,0,0,0) 	=> 	26/MT
### 
### ADDITIONAL COLORS
### 27	midgrey				#D7D8D7
### 28	very lightgrey		#ECECEC
### 29	white				#FFFFFF
### 30	black				#000000
### --------------------------------------------------------------------------------------------------------------------
