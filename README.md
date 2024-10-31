GWASToolKit
============
[![DOI](https://zenodo.org/badge/55601542.svg)](https://zenodo.org/badge/latestdoi/55601542)

[![Languages](https://skillicons.dev/icons?i=bash,r,py)](https://skillicons.dev) 

This repository contains various scripts in Perl, BASH, and Python scripts to use in genome-wide association studies, single variant analyses, regional analyses, and gene-centered analyses. The genotypes are expected to be imputed using [IMPUTE2](http://mathgen.stats.ox.ac.uk/impute/impute_v2.html) and the core of the collection of scripts makes use of [SNPTEST v2.5.4+](https://mathgen.stats.ox.ac.uk/genetics_software/snptest/snptest.html)and [QCTOOL v2.0.2+](https://www.well.ox.ac.uk/~gav/qctool/#overview). 

All scripts are annotated for debugging purposes - and future reference. The scripts will work within the context of a certain Linux environment (in this case a _CentOS7_ system with _Simple Linux Utility for Resource Management [SLURM]_). As such we have tested GWASToolKit on CentOS6.6, CentOS7, and macOS since El Capitan (version 10.11.[x]). 


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

#### USAGE 
The only script the user should use is the `gwastoolkit.analyzer.sh` script in conjunction with a configuration file `gwastoolkit.conf`. 

By typing...

```
bash gwastoolkit.analyzer.sh $(pwd)/gwastoolkit.conf
```

...the user will control what analysis will be done. Simply typing `bash gwastoolkit.analyzer.sh` will produce an extensive error-message explaining what arguments are expected. 

> Note: it is absolutely pivotal to use `$(pwd)` to indicate the whole path to the configuration file, because this is used by the script(s) for the creation of directories _etc._ 

--------------

#### GWAS 
A GWAS will be run on the selected dataset. LocusZoom style figures, Manhattan plots, QQ-plots and other informative plots will be made automatically made. Some relevant statistics, such as HWE, minor allele count (MAC), and coded allele frequency (CAF) will also be added to the final summarized result. 

--------------

#### Per-Variant analyses

The user must supply a variant list with chromosome and base pair position per variant. The final analyses results will be concatenated into a summary file.

--------------

#### Regional analyses

The user must supply a region of interest in a file. The final analyses results will be concatenated into a summary file. Regional association plots will automatically be generated. 

--------------

#### Per-Gene analyses

The user must supply a variant list with chromosome and base pair position per variant. The final analyses results will be concatenated into a summary file. Regional association plots will automatically be generated.


--------------

#### MoSCoW (must, should, could, would) - TO DO
There are definitely improvements needed. Below of things I'd like to add or edit in the (near) future (also refer to Issues-tab).

- [x] ~~edit the variant selection to work with non-rsID variants~~ this now works based on `chromosome-basepair` position.
- [.] add proper `--help` flag -- SHOULD
- [.] clean up codes further, especially with respect to the various error-flags -- COULD
- [.] add in checks of the environment, similar to `slideToolKit` scripts -- COULD
- [.] add in some code to produce a simple report -- SHOULD
- [.] create wiki -- MUST
- [x] ~~update to SLURM~~ this was update, kudos to [@ediezben](https://github.com/ediezben).
- [.] clean up code using ChatGPT -- MUST
- [.] clean up code integrating `GWASLab` -- MUST
- [.] replace LocusZoom with `RACER` -- MUST

--------------

#### The MIT License (MIT)
##### Copyright (c) 2010-2020 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:   

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Reference: http://opensource.org.
