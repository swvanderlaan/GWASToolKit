#!/hpc/local/CentOS7/dhl_ec/software/R-3.4.0/bin/Rscript --vanilla

### Mac OS X version
### #!/usr/local/bin/Rscript --vanilla

### Linux version
### #!/hpc/local/CentOS7/dhl_ec/software/R-3.3.3/bin/Rscript --vanilla

cat("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Manhattan Plotter -- MetaGWASToolKit
    \n
    * Version: v1.2.0
    * Last edit: 2019-12-14
    * Created by: Sander W. van der Laan | s.w.vanderlaan@gmail.com
    \n
    * Description:  Manhattan-plotter for GWAS (meta-analysis) results. Can produce output 
      in different colours and image-formats. Three columns are expected:
      1) with chromosomes (1-22, X, Y, XY, MT)
      2) with basepair position
      3) with test-statistic (P-value)
      NO HEADER.
    The script should be usuable on both any Linux distribution with R 3+ installed, Mac OS X and Windows.
    
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")

# usage: ./manhattan.R -p projectdir -r resultfile -o outputdir -c colorstyle -f imageformat [OPTIONAL: -t titleplot -v verbose (DEFAULT) -q quiet]
#        ./manhattan.R --projectdir projectdir --resultfile resultfile --outputdir outputdir --colorstyle colorstyle --imageformat imageformat [OPTIONAL: --titleplot titleplot --verbose verbose (DEFAULT) -quiet quiet]

cat("\n* Clearing the environment...\n\n")
#--------------------------------------------------------------------------
### CLEAR THE BOARD
# rm(list = ls())

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
  if (isTRUE(x %in% .packages(all.available = TRUE))) { 
    eval(parse(text = sprintf("require(\"%s\")", x)))
  } else { 
    # Update installed packages - this may mean a full upgrade of R, which in turn
    # may not be warrented. 
    #update.packages(ask = FALSE) 
    eval(parse(text = sprintf("install.packages(\"%s\", dependencies = TRUE, repos = \"http://cran-mirror.cs.uu.nl/\")", x)))
  }
  if (isTRUE(x %in% .packages(all.available = TRUE))) { 
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
uithof_color = c("#FBB820","#F59D10","#E55738","#DB003F","#E35493","#D5267B",
                 "#CC0071","#A8448A","#9A3480","#8D5B9A","#705296","#686AA9",
                 "#6173AD","#4C81BF","#2F8BC9","#1290D9","#1396D8","#15A6C1",
                 "#5EB17F","#86B833","#C5D220","#9FC228","#78B113","#49A01D",
                 "#595A5C","#A2A3A4", "#D7D8D7", "#ECECEC", "#FFFFFF", "#000000")

#--------------------------------------------------------------------------
### OPTION LISTING
option_list = list(
  make_option(c("-p", "--projectdir"), action = "store", default = NA, type = 'character',
              help = "Path to the project directory."),
  make_option(c("-r", "--resultfile"), action = "store", default = NA, type = 'character',
              help = "Path to the results directory, relative to the project directory."),
  make_option(c("-c", "--colorstyle"), action = "store", default = NA, type = 'character',
              help = "The color style of the Manhattan plot: 
                 \n- FULL:      multicolor panel, no highlighting
                 \n- TWOCOLOR:  twocolor (#1290D9 [azurblue], #E35493 [lightpink]), with highlighting in (#DB003F)
                 \n- TWOCOLOR_B:  twocolor (#4C81BF [seablue], #1290D9 [azurblue]), with highlighting in (#DB003F)
                 \n- TWOCOLOR_R:  twocolor (#E55738 [salmon], #1290D9 [azurblue]), with highlighting in (#DB003F)
                 \n- TWOCOLOR_G:  twocolor (#49A01D [green], #1290D9 [azurblue]), with highlighting in (#DB003F)
                 \n- QC:        twocolor (#595A5C [grey], #A2A3A4 [lightgrey]), with highlighting in (#DB003F), 
                 \n              but p-values truncated at -log10(p-value)=2, for quick inspection/QC-purposes."),
  make_option(c("-f", "--imageformat"), action = "store", default = NA, type =  'character',
              help = "The image format (PDF (width=10, height=5), PNG/TIFF/EPS (width=1280, height=720)."),
  make_option(c("-o", "--outputdir"), action = "store", default =  NA, type = 'character',
              help = "Path to the output directory."),
  make_option(c("-t", "--titleplot"), action = "store", default = "Manhattan-plot", type = 'character',
              help = "The title of the plot? [default %default]"),
  make_option(c("-v", "--verbose"), action = "store_true", default = TRUE,
              help = "Should the program print extra stuff out? [default %default]"),
  make_option(c("-q", "--quiet"), action = "store_false", dest = "verbose",
              help = "Make the program not be verbose.")
  # make_option(c("-c", "--cvar"), action="store", default="this is c",
  #             help="a variable named c, with a default [default %default]")  
)
opt = parse_args(OptionParser(option_list = option_list))

#--------------------------------------------------------------------------
# 
# ### FOR LOCAL DEBUGGING
# ### MacBook Pro
# MACDIR = "/Users/swvanderlaan"
# ### Mac Pro
# # MACDIR="/Volumes/MyBookStudioII/Backup"
# 
# opt$projectdir = paste0(MACDIR, "/PLINK/analyses/meta_gwasfabp4/ANALYSES2019/MANUSCRIPT")
# opt$outputdir = paste0(MACDIR, "/PLINK/analyses/meta_gwasfabp4/ANALYSES2019/MANUSCRIPT/PLOTS")
# opt$colorstyle = "QC"
# opt$imageformat = "PNG"
# opt$titleplot = "MODEL 3"
# opt$resultfile = paste0(MACDIR, "/PLINK/analyses/meta_gwasfabp4/ANALYSES2019/MANUSCRIPT/OUTPUT/meta.GWAS.FABP4.1Gp1.EUR.MODEL3.summary.QCed.mh.txt.gz")
# #opt$resultfile = paste0(MACDIR, "/iCloud/Downloads/Heleen/HTN_mht.txt")
# ### FOR LOCAL DEBUGGING
# 
#--------------------------------------------------------------------------

if (opt$verbose) {
  # if (opt$verbose) {
  # you can use either the long or short name
  # so opt$a and opt$avar are the same.
  # show the user what the variables are
  cat("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
  cat("Checking the settings.")
  cat("\nThe project directory....................: ")
  cat(opt$projectdir)
  cat("\nThe results file.........................: ")
  cat(opt$resultfile)
  cat("\nThe output directory.....................: ")
  cat(opt$outputdir)
  cat("\nThe color style..........................: ")
  cat(opt$colorstyle)
  cat("\nThe image format.........................: ")
  cat(opt$imageformat)
  cat("\nThe title of the plot....................: ")
  cat(opt$titleplot)
  cat("\n\n")
  
}
cat("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
cat("Wow. We are finally starting \"Mahattan Plotter\". ")
#--------------------------------------------------------------------------
### START OF THE PROGRAM
# main point of program is here, do this whether or not "verbose" is set
if (!is.na(opt$projectdir) & !is.na(opt$resultfile) & !is.na(opt$outputdir) & !is.na(opt$colorstyle) & !is.na(opt$imageformat)) {
  study <- file_path_sans_ext(basename(opt$resultfile)) # argument 2
  filename <- basename(opt$resultfile)
  cat(paste("We are going to a make Manhattan-plot of your (meta-)GWAS results. \nData are taken from.........: '",filename,"'\nand will be outputed in.....: '", opt$outputdir, "'.\n",sep = ''))

  #--------------------------------------------------------------------------
  ### GENERAL SETUP
  Today = format(as.Date(as.POSIXlt(Sys.time())), "%Y%m%d")
  cat(paste("\nToday's date is: ", Today, ".\n", sep = ''))
  #Time=format(as.POSIXlt(Sys.time()), "%H:%M:%S")
  
  #--------------------------------------------------------------------------
  ### DEFINE THE LOCATIONS OF DATA
  ROOT_loc = opt$projectdir # argument 1
  OUT_loc = opt$outputdir # argument 4
  
  #--------------------------------------------------------------------------
  ### DEFINE MANHATTAN FUNCTIONS
  ### REFERENCE: 
  ### Link: https://rdrr.io/bioc/ramwas/man/manhattan.html
  ### Taken from the `ramwas` library by Andrey A Shabalin (andrey.shabalin@gmail.com)
  
  # Prepare data - this increases speed of plotting
  PrepareManhattanPlot <- function(pvalues, chr, pos, ismlog10 = FALSE, chrmargins = 5e+06) {
    stopifnot(length(pvalues) == length(chr))
    stopifnot(length(pvalues) == length(pos))
    if (is.double(chr)) 
      chr = as.integer(chr)
    if (is.character(chr)) 
      chr = factor(chr)
    if (is.integer(chr)) {
      levels(chr) = as.character(seq_len(tail(chr, 1)))
      class(chr) = "factor"
    }
    poslist = split(pos, chr, drop = FALSE) 
    poslist[sapply(poslist, length) == 0L] = list(0)
    chrmax = sapply(poslist, max) + 0
    names(chrmax) = NULL
    offsets = c(0, cumsum(chrmax)) + chrmargins
    names(offsets)[seq_along(poslist)] = levels(chr)
    x0 = offsets[unclass(chr)] + pos
    if (ismlog10) {
      y0 = pvalues
    }
    else {
      y0 = -log10(pvalues)
    }
    yfac = as.integer(y0 * 100) + 1L
    yorder = sort.list(yfac)
    levels(yfac) = as.character(seq_len(max(yfac)))
    class(yfac) = "factor"
    ygroup = split(seq_along(yfac), yfac)
    for (i in seq_along(ygroup)) {
      if (length(ygroup[[i]]) > 300) {
        ygroup[[i]] = sample(ygroup[[i]], size = 300, replace = FALSE)
      }
    }
    keep = unlist(ygroup, use.names = FALSE)
    colindex = unclass(chr)
    chrnames = gsub("chr", "", levels(chr))
    man = list(x = x0[keep], y = y0[keep], colindex = colindex[keep], 
               offsets = offsets, chrnames = chrnames, chrmargins = chrmargins)
    class(man) = "FastManhattanPlotInfo"
    return(man)
  }
  
  # Plotting function
  FastManhattanPlot <- function(man, ylim = NULL, 
                                colorSet = c("steelblue4", "#2C82D1", "#4CB2D1"), 
                                yaxmax = NULL, lwd = 2, axistep = 2, cex = 1, ...) {
    if (class(man) != "FastManhattanPlotInfo") 
      stop("The \"man\" parameter is not produced by PrepareManhattanPlot().")
    if (is.null(ylim)) {
      my = max(man$y) * 1.05
      ylim = c(0, my)
    }
    else {
      my = ylim[2]
    }
    if (is.null(yaxmax)) 
      yaxmax = floor(my)
    plot(x = NA, y = NA, xlim = c(0, tail(man$offsets, 1)), ylim = ylim, 
         main = paste0("",opt$titleplot,""),
         xaxs = "i", yaxs = "i", xlab = "chromosome", 
         ylab = bquote(-log[10]~"("~italic(p)~"-value)"), axes = FALSE)
    axis(side = 1, at = man$offsets, labels = rep("", length(man$offsets)), 
         lwd = lwd)
    axis(side = 1, at = (man$offsets[-1] + man$offsets[-length(man$offsets)])/2, 
         labels = man$chrnames, tick = FALSE, lwd = lwd)
    axis(side = 2, at = seq(0, yaxmax, axistep), lwd = lwd)
    oldPal = palette(colorSet)
    points(x = man$x, y = man$y, pch = 20, col = ((man$colindex - 
                                                     1L)%%length(colorSet)) + 1L, cex = cex)
    palette(oldPal)
  }
  #--------------------------------------------------------------------------
  ### LOADING RESULTS FILE
  ### Location of is set by 'opt$resultfile' # argument 2
  cat("\n\nLoading results file and removing NA's.")
  
  ### Checking file type -- is it gzipped or not?
  data_connection <- file(opt$resultfile)
  filetype <- summary(data_connection)$class
  close(data_connection)
  
  ### Loading the data
  if (filetype == "gzfile") {
    cat("\n* The file appears to be gzipped, now loading...\n")
    rawdata = fread(paste0("zcat < ",opt$resultfile), header = FALSE, blank.lines.skip = TRUE)
  } else if (filetype != "gzfile") {
    cat("\n* The file appears not to be gzipped, now loading...\n")
    rawdata = fread(opt$resultfile, header = FALSE, blank.lines.skip = TRUE)
  } else {
    cat("\n\n*** ERROR *** Something is rotten in the City of Gotham. We can't determine the file type 
of the data. Double back, please.\n\n", 
        file = stderr()) # print error messages to stder
  }
  cat("\n* Removing NA's...")
  data <- na.omit(rawdata)

  cat("\n\nReformatting chromosomes: X/XY/Y/MT to 23/24/25/26.")
  data$V1 = toupper(data$V1) #convert to upper case
  cat("\n- chromosome 'X' to '23'....")
  data$V1[data$V1 == "0X"] = "23"
  data$V1[data$V1 == "X"] = "23"
  cat("\n- chromosome 'Y' to '24'....")
  data$V1[data$V1 == "0Y"] = "24"
  data$V1[data$V1 == "Y"] = "24"
  cat("\n- chromosome 'XY' to '25'....")
  data$V1[data$V1 == "XY"] = "25"
  cat("\n- chromosome 'MT' to '26'....")
  data$V1[data$V1 == "MT"] = "26"
  data$V1[data$V1 == "M"] = "26"
  data$V1 = as.integer(data$V1)
  data$V2 = as.integer(data$V2)
  data$V3 = as.numeric(data$V3)
  data$V4 <- data$V3
  
  minP <- min(subset(data, V3 != 0, c(V3)))
  data <- transform(data, V4 = ifelse(V4 == 0, minP, V4))
  
  cat(paste0("\n\nCorrected 'zero'-p-values; the smallest p-values is ", format(min(data$V4), digits = 3),"."))
  
  cat("\n\nReordering data.")
  # V1 = chromosome
  # V2 = base pair position
  setkey(data, V1, V2)

  cat("\n\nPrepare the data for speedgain.")
  data.prep <- PrepareManhattanPlot(data$V4, data$V1, data$V2)

  cat("...and make a list of colors.")
  uithof_color_full = uithof_color
  uithof_color_two = c("#1290D9","#E35493")
  uithof_color_two_blue = c("#4C81BF", "#1290D9")
  uithof_color_two_red = c("#E55738", "#1290D9")
  uithof_color_two_green = c("#49A01D", "#1290D9")
  uithof_color_qc = c("#595A5C","#A2A3A4")
  
  cat("\n\nSetting X- and Y-axes and counting chromosomes.")
  maxY <- round(max(-log10(data$V4)))
  cat(paste0("\n* The maximum on the Y-axis: ", round(maxY, digits = 0),"."))

  # Let's count the number of chromosomes to plot
  nchr = length(unique(data$V1))
  cat(paste0("\n* The number of chromosomes to plot: ", nchr,"; these are:"))

  # Take into account unique chrs
  uniq_chr = unique(data$V1)
  # Can be used for debugging
  # cat(paste0("\n- chromosome [ ", uniq_chr," ]"))
  
  cat("\n\nDetermining the 'maxX'.\n")
  # We have determined the number of chromosomes (1-22 plus optionally x, y, etc.),
  # and will plot accordingly. This includes the maximum number of chromosomes.
  maxX = 0 # setting maxX at 'zero'
  #changed to uniq_chr loop
  for (i in 1:length(uniq_chr)) {
    # Can be used for debugging
    # cat(paste0("- chromosome [ ",i," ]\n"))
    # getting a list of positions per chromosome
    # assign((paste("pos_", i, sep = "")), (subset(data$V2, data$V1 == uniq_chr[i])))
    # getting a list of p-values per chromosome
    # assign((paste("p_", i, sep = "")), (subset(data$V4, data$V1 == uniq_chr[i])))  
    # calculating the maxX based on the input-data
    maxX = maxX + max(subset(data$V2, data$V1 == uniq_chr[i]))  
  }
  cat(paste0("\n\n* The maximum on the X-axis: ", format(maxX, big.mark = ","),"."))
  
  ### PLOT MANHATTAN ###
  cat("\n\nDetermining what type of image should be produced and plotting axes.")
  if (opt$imageformat == "PNG")
    if (opt$colorstyle == "FULL") {
      png(paste0(opt$outputdir,"/",study,".",opt$colorstyle,".png"), width = 1280, height = 720)
    } else if (opt$colorstyle == "TWOCOLOR" | opt$colorstyle == "TWOCOLOR_B" | opt$colorstyle == "TWOCOLOR_R" | opt$colorstyle == "TWOCOLOR_G") {
      png(paste0(opt$outputdir,"/",study,".",opt$colorstyle,".png"), width = 1280, height = 720)
    } else {
      png(paste0(opt$outputdir,"/",study,".",opt$colorstyle,".png"), width = 1280, height = 720)
    }
  if (opt$imageformat == "TIFF")
    if (opt$colorstyle == "FULL") {
      tiff(paste0(opt$outputdir,"/",study,".",opt$colorstyle,".tiff"), width = 1280, height = 720)
    } else if (opt$colorstyle == "TWOCOLOR" | opt$colorstyle == "TWOCOLOR_B" | opt$colorstyle == "TWOCOLOR_R" | opt$colorstyle == "TWOCOLOR_G") {
      tiff(paste0(opt$outputdir,"/",study,".",opt$colorstyle,".tiff"), width = 1280, height = 720)
    } else {
      tiff(paste0(opt$outputdir,"/",study,".",opt$colorstyle,".tiff"), width = 1280, height = 720)
    }
  
  if (opt$imageformat == "EPS")
    if (opt$colorstyle == "FULL") {
      postscript(file = paste0(opt$outputdir,"/",study,".",opt$colorstyle,".ps"),
                 horizontal = FALSE, onefile = FALSE, paper = "special")
    } else if (opt$colorstyle == "TWOCOLOR" | opt$colorstyle == "TWOCOLOR_B" | opt$colorstyle == "TWOCOLOR_R" | opt$colorstyle == "TWOCOLOR_G") {
      postscript(file = paste0(opt$outputdir,"/",study,".",opt$colorstyle,".ps"),
                 horizontal = FALSE, onefile = FALSE, paper = "special")
    } else {
      postscript(file = paste0(opt$outputdir,"/",study,".",opt$colorstyle,".ps"),
                 horizontal = FALSE, onefile = FALSE, paper = "special")
    }
  if (opt$imageformat == "PDF")
    if (opt$colorstyle == "FULL") {
      pdf(paste0(opt$outputdir,"/",study,".",opt$colorstyle,".pdf"), width = 10, height = 5)
    } else if (opt$colorstyle == "TWOCOLOR" | opt$colorstyle == "TWOCOLOR_B" | opt$colorstyle == "TWOCOLOR_R" | opt$colorstyle == "TWOCOLOR_G") {
      pdf(paste0(opt$outputdir,"/",study,".",opt$colorstyle,".pdf"), width = 10, height = 5)
    } else {
      pdf(paste0(opt$outputdir,"/",study,".",opt$colorstyle,".pdf"), width = 10, height = 5)
    }
  
  ### START PLOTTING ###
  cat("\n\nPlotting.")
  if (opt$colorstyle == "FULL") {
    FastManhattanPlot(man = data.prep, 
                      ylim = c(0, 12), 
                      colorSet = uithof_color_full, cex = 2)
  } else if (opt$colorstyle == "TWOCOLOR") {
    FastManhattanPlot(man = data.prep, 
                      ylim = c(0, 12), 
                      colorSet = uithof_color_two, cex = 2)
  } else if (opt$colorstyle == "TWOCOLOR_B") {
    FastManhattanPlot(man = data.prep, 
                      ylim = c(0, 12), 
                      colorSet = uithof_color_two_blue, cex = 2)
  } else if (opt$colorstyle == "TWOCOLOR_R") {
    FastManhattanPlot(man = data.prep, 
                      ylim = c(0, 12), 
                      colorSet = uithof_color_two_red, cex = 2)
  } else if (opt$colorstyle == "TWOCOLOR_G") {
    FastManhattanPlot(man = data.prep, 
                      ylim = c(0, 12), 
                      colorSet = uithof_color_two_green, cex = 2)
  } else {
    FastManhattanPlot(man = data.prep, 
                      ylim = c(0, 12), 
                      colorSet = uithof_color_qc, cex = 2)
  }
  
  cat("\n* Adding the genome-wide significance threshold.\n")
  lines(c(0, maxX), c(-log10(5e-08), -log10(5e-08)), lwd = 2, lty = "dotted", col = "#595A5C")
  
  dev.off()
  
} else {
  cat("\n\n\n\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
  cat("\n*** ERROR *** You didn't specify all variables:\n
         - --p/projectdir  : path to project directory\n
         - --r/resultfile  : path to resultfile\n
         - --o/outputdir   : path to output directory\n
         - --c/colorstyle  : the color style to be used (FULL, TWOCOLOR or QC)\n
         - --f/imageformat : the image format (PDF, PNG, TIFF or PostScript)\n
         - --t/title       : the title on the plot (optional)\n\n", 
      file = stderr()) # print error messages to stderr
}

#--------------------------------------------------------------------------
### CLOSING MESSAGE
cat(paste("\nAll done plotting a Manhattan-plot of",study,".\n"))
cat(paste("\nToday's: ",Today, "\n"))
cat("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")

#--------------------------------------------------------------------------
#
# ### SAVE ENVIRONMENT | FOR DEBUGGING
# save.image(paste0(OUT_loc, "/", Today,"_",study,"_",opt$colorstyle,"_DEBUG_MANHATTANPLOTTER.RData"))

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
