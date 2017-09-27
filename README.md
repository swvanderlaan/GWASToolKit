GWASToolKit
============
This repository contains various scripts in Perl, BASH, and Python scripts to use in genome-wide association studies, single variant analyses, regional analyses, and gene-centered analyses using data of the Athero-Express Genomics Studies 1 and 2 (AEGS), AAA-Express Genomics Study (AAAGS), or CTMM Genomics Study (CTMM).

Scripts will work within the context of a certain Linux environment (in this case a CentOS7 system on a SUN Grid Engine background). 

All scripts are annotated for debugging purposes - and future reference. The only script the user should edit is the `run_analysis.sh` script, and depending on the analyses to be run, some text-files.

The installation procedure is quite straightforward, and only entails two steps consisting of command one-liners that are *easy* to read. You can copy/paste each example command, per block of code. For some steps you need administrator privileges. Follow the steps in consecutive order.

```
these `mono-type font` illustrate commands illustrate terminal commands. You can copy & paste these.
```

To make it easier to copy and paste, long commands that stretch over multiple lines are structered as follows:

```
Multiline commands end with a dash \
	indent 4 spaces, and continue on the next line. \
	Copy & paste these whole blocks of code.
```

Although we made it easy to just select, copy and paste and run these blocks of code, it is not a good practise to blindly copy and paste commands. Try to be aware about what you are doing. And never, never run `sudo` commands without a good reason to do so. 

We have tested GWASToolKit on CentOS6.6, CentOS7, and OS X El Capitan (version 10.11.[x]). 


--------------

#### Installing the scripts locally

You can use the scripts locally to run analyses on a Unix-based system, like Mac OS X (Mountain Lion+). We need to make an appropriate directory to download 'gits' to, and install this 'git'.

##### Step 1: make a directory, and go there.

```
mkdir -p ~/git/ && cd ~/git
```

##### Step 2: clone this git, unless it already exists.

```
if [ -d ~/git/GWASToolKit/.git ]; then \
		cd ~/git/GWASToolKit && git pull; \
	else \
		cd ~/git/ && git clone https://github.com/swvanderlaan/GWASToolKit.git; \
	fi
```


--------------

#### GWAS 
A GWAS will be run on the selected dataset. LocusZoom style figures, Manhattan plots, QQ-plots and other informative plots will be made automatically made. Some relevant statistics, such as HWE, minor allele count (MAC), and coded allele frequency (CAF) will also be added to the final summarized result. 

--------------

#### Per-Variant analyses

The user must supply a variant list with chromosome and base pair position per variant. The final analyses results will be concatenated into a summary file.

--------------

#### Regional analyses

The user must supply a region of interest in a file. The final analyses results will be concatenated into a summary file. 

--------------

#### Per-Gene analyses

The user must supply a variant list with chromosome and base pair position per variant. The final analyses results will be concatenated into a summary file.


--------------

#### TO DO

- add proper `--help` flag
- clean up codes further, especially with respect to the various error-flags
- add in checks of the environment, similar to `slideToolkit` scripts
- add in some code to produce a simple report

--------------

#### The MIT License (MIT)
####Copyright (c) 2015-2017 Sander W. van der Laan | s.w.vanderlaan-2 [at] umcutrecht.nl

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:   

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Reference: http://opensource.org.
