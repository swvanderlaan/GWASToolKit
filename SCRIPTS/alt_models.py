#!/usr/bin/env python3

# Change log
# * v1.0.0 2024-04-11: Initial version.
# Version information
VERSION_NAME = 'AltModels'
VERSION = '1.0.0'
VERSION_DATE = '2024-04-11'
COPYRIGHT = 'Copyright 1979-2024. Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com | https://vanderlaanand.science.'
COPYRIGHT_TEXT = f'\nThe MIT License (MIT). \n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and \nassociated documentation files (the "Software"), to deal in the Software without restriction, \nincluding without limitation the rights to use, copy, modify, merge, publish, distribute, \nsublicense, and/or sell copies of the Software, and to permit persons to whom the Software is \nfurnished to do so, subject to the following conditions: \n\nThe above copyright notice and this permission notice shall be included in all copies \nor substantial portions of the Software. \n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, \nINCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR \nPURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS \nBE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, \nTORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE \nOR OTHER DEALINGS IN THE SOFTWARE. \n\nReference: http://opensource.org.'

# Fixed variables
# Some general settings
SOFTWARE = "/hpc/local/Rocky8/dhl_ec/software"
# Path to PLINK
# PLINK19 = "{SOFTWARE}/plink19"
PLINK19 = "/Users/slaan3/bin/plink19"
PLINK2 = "/Users/slaan3/bin/plink2"
# Genetic data paths
# GENDATA = "/hpc/dhl_ec/data/_ae_originals/AEGS_COMBINED_EAGLE2_1000Gp3v5HRCr11/aegs.qc.1kgp3hrcr11.idfix"
GENDATA = "/Users/slaan3/PLINK/_AE_ORIGINALS/AEGS_COMBINED_EAGLE2_1000Gp3v5HRCr11/aegs.qc.1kgp3hrcr11.idfix"

# Import required packages
import os
import argparse
from argparse import RawTextHelpFormatter
import shutil
import time
from datetime import datetime
from datetime import timedelta
import subprocess

def submit_jobs(phenotypes, phenofile, covariates, glm, snp, chromosome, projectdir, outputdir, model=None, interaction=None, interactionparam=None, sex="sex", execute=False, submit=False, mailtype="FAIL", memory="8G", time="00:15:00", email="s.w.vanderlaan-2@umcutrecht.nl", verbose=False):
    
    # Remove any extra characters from paths
    phenofile = phenofile[0]  # Extract the first element of the list
    # covariates = ", ".join(covariates)  # Join covariates into a comma-separated string
    # selection = selection[0]  # Extract the first element of the list
    # selectionfile = selectionfile[0]  # Extract the first element of the list
    # Format project directory and output directory paths
    projectdir = os.path.abspath(projectdir)
    outputdir = os.path.abspath(outputdir)

    # if model is None:
    #     model = ""
    # if sex is None:
    #     sex = ""
    # if interaction is None:
    #     interaction = ""
    
    # Print extra information
    print(f"Running {glm} regression for SNP {snp} on chromosome {chromosome} using model {model}.")
    
    # check sex correction
    if sex == "sex":
        print(f"By default analyses are corrected for sex (based on the presence of chromosome X).")
    elif sex == "no-x-sex":
        print(f"Analyses are not corrected for sex (based on the presence of chromosome X).")
    else:
        print(f"Sex correction: {sex}")
    
    # check interaction
    if interaction == "interaction":
        print(f"Adding interaction tests using --parameter {interactionparam}.")
    else:
        print(f"No interaction tests are executed.")
    
    # check if model is provided
    if model is None:
        print(f"No model is provided. Using default additive {glm} model.")
    else:
        print(f"Using {model} model for {glm} analysis.")

    # print additional information
    if verbose: 
        print(f"PLINK location: {PLINK19}")
        print(f"Phenotypes are read from file {phenofile}.")
        print(f"The following phenotypes are tested: [{', '.join(phenotypes)}]")
        print(f"In addition the following covariates are included: [{', '.join(covariates)}]")
        # print(f"Data are filtered on value {selection} in {selectionfile}.")
        print(f"Project directory: {projectdir}")
        print(f"Output directory: {outputdir}")
        if submit:
            print(f"Submitting SLURM jobs.")
            print(f"Email address: {email}")
            print(f"Mail type settings: {mailtype}")
            print(f"Memory allocation: {memory}")
            print(f"Time allocation: {time}")
        else:
            print(f"Printing commands.")
    
    # Define PLINK command based on model
    # ref: https://www.cog-genomics.org/plink/1.9/input#vcf
    # --const-fid converts sample IDs to within-family IDs while setting all family IDs to a single value (default '0').
    # ref: https://www.cog-genomics.org/plink/1.9/input#plink_irreg
    # --no-sex
    # ref: https://www.cog-genomics.org/plink/1.9/assoc#linear
    # interaction 
    if model is None:
        if interaction:
            if interactionparam is None:
                plink_command = f"{PLINK2} --vcf {GENDATA}.chr{chromosome}.vcf.gz --const-fid --glm {sex} {interaction} --no-sex --covar-variance-standardize"
            else:
                plink_command = f"{PLINK2} --vcf {GENDATA}.chr{chromosome}.vcf.gz --const-fid --glm {sex} {interaction} --parameters {interactionparam} --no-sex --covar-variance-standardize"
        else: 
            plink_command = f"{PLINK19} --vcf {GENDATA}.chr{chromosome}.vcf.gz --const-fid --{glm} {sex} --no-sex --missing-code -9" 
    else:
        if interaction:
            if interactionparam is None:
                plink_command = f"{PLINK2} --vcf {GENDATA}.chr{chromosome}.vcf.gz --const-fid --glm {model} {sex} {interaction} --no-sex --covar-variance-standardize"
            else:
                plink_command = f"{PLINK2} --vcf {GENDATA}.chr{chromosome}.vcf.gz --const-fid --glm {model} {sex} {interaction} --parameters {interactionparam} --no-sex --covar-variance-standardize"
        else: 
            plink_command = f"{PLINK19} --vcf {GENDATA}.chr{chromosome}.vcf.gz --const-fid --{glm} {model} {sex} --no-sex --missing-code -9"
    
    # Construct output name
    if model is None:
        output_name = f"{glm}_chr{snp.replace(':', '-')}"
    else:
        output_name = f"{glm}_{model}_chr{snp.replace(':', '-')}"

    # Submit jobs for each phenotype
    for phenotype in phenotypes:
        # Command to run PLINK
        command = f"{plink_command} --pheno {projectdir}/{phenofile} --pheno-name {phenotype} --covar {projectdir}/{phenofile} --covar-name {', '.join(covariates)} --snp {snp} --out {outputdir}/{output_name}_{phenotype}"

        # Submit job or print command
        if submit:
            os.system(f"sbatch --mail-user {email} --mail-type {mailtype} --mem {memory} --time {time} --job-name {phenotype} --output {outputdir}/slurm-%j.out --error {outputdir}/slurm-%j.err --wrap '{command}'")
        else:
            print(f"- testing {phenotype}")
            if verbose:
                print(command)
                print()
            # Execute the command
            if execute:
                subprocess.run(command, shell=True)

# Define main function
def main():
    parser = argparse.ArgumentParser(description=f'''
+ {VERSION_NAME} v{VERSION} +

This script runs logistic (`--logistic`) or linear regression (`--linear`) in PLINK v1.9 for a 
given SNP (`--snp`) and chromosome (`--chr`) and a given list of phenotypes (`--phenotypes`) 
and covariates (`--covariates`). The phenotypes and covariates are assumed to be in the same
file (`--phenofile`). By default analyses are corrected for sex (`--sex`). 
The analysis will be run within a given project directory (`--projectdir`) and output 
directory (`--outputdir`). 

Optionally, the script will run the analysis for each phenotype separately while applying 
a given genetic model (`--model`). By default the 'additive' model is assumed. 

Optionally, the script will run an interaction analysis (`--interaction`), by default 
this is done on all combinations, which can be changed using `--interactionparam`. The 
interaction analysis is run in PLINK v2.0.

By default the script will print the commands to run the analysis. Use the `--execute` flag to
run the commands. Optionally, the script will submit SLURM jobs for each phenotype. In that case 
a user can provide their email address (`--email`) and mail type settings (`--mailtype`). The 
memory allocation for each job can be set using the `--memory` flag, and the time allocation 
using the `--time` flag.

Use the `--verbose` flag to print extra information.

To get more information on the script, please use the `--help` flag. The `--version` flag will provide
you with the version information.

It is assumed that the genetic data is stored in VCF v4.2 format.

Example usage:
python alt_models.py --glm logistic --model genotypic --phenotypes pheno1 pheno2 pheno3 --phenofile phenocov.txt --covariates cov1 cov2 cov3 --selection "selected" --selectioncol 3 --snp rs123456 --chr 20 --projectdir /hpc/project/super_project --outputdir /hpc/project/super_project/output 
        ''',
        epilog=f'''
+ {VERSION_NAME} v{VERSION}. {COPYRIGHT} \n{COPYRIGHT_TEXT}+''', 
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("--phenotypes", "-ph", nargs="+", help="List of phenotypes. For example: 'phenotype1 phenotype2 phenotype3'.")
    parser.add_argument("--phenofile", "-pf", nargs="+", help="File containing the phenotypes. For example: 'phenocov.txt'.")
    parser.add_argument("--covariates", "-c", nargs="+", help="List of covariates. For example: 'covariate1 covariate2 covariate3'.")
    # parser.add_argument("--selection", "-sel", nargs="+", help="Value to filter data on; assuming this column is present in the phenocov-file. For example: 'selected'. Optional. [NOT IMPLEMENTED YET]")
    # parser.add_argument("--selectionfile", "-sf", nargs="+", help="File containing the to-be selected samples. For example: 'selection.txt'. Optional. [NOT IMPLEMENTED YET]")
    parser.add_argument("--glm", "-g", choices=["logistic", "linear"], default="logistic", help="Statistical test to use. Options: linear, logistic. Default: logistic.")
    parser.add_argument("--model", "-m", choices=["genotypic", "dominant", "recessive"], help="Model to use. Options: genotypic, dominant, recessive. Default: genotypic. Optional")
    parser.add_argument("--interaction", "-i", choices=["interaction"], help="Add in interaction analysis. Optional.")
    parser.add_argument("--interactionparam", "-ip", choices=["1", "2", "3", "4", "5", "6", "7"], help="Add interaction parameter (see https://www.cog-genomics.org/plink/1.9/assoc#linear); use with `--interaction`. Optional.")
    parser.add_argument("--sex", choices=["sex", "no-x-sex"], default="sex", help="By default sex is added as covariate (based on the presence of chromosome X). Default: sex. Optional.")
    parser.add_argument("--snp", help="SNP to test. For example: 'rs123456' or '20:123456'.")
    parser.add_argument("--chromosome", "-chr", help="Chromosome to analyze. For example: '20'.")
    parser.add_argument("--projectdir", "-p", default = "/hpc/project/super_project", help="Project directory. For example: '/hpc/project/super_project'")
    parser.add_argument("--outputdir", "-o", default = "/hpc/project/super_project/output", help="Output directory. For example: '/hpc/project/super_project/output'")
    parser.add_argument("--execute", "-ex", default=False, help="Execute the command. Default: print commands. Optional.")
    parser.add_argument("--submit", "-s", default=False, help="Submit SLURM jobs. Default: print commands. Optional.")
    parser.add_argument("--email", "-e", default="s.w.vanderlaan-2@umcutrecht.nl", help="Your email address. Default: s.w.vanderlaan-2@umcutrecht.nl. Optional.")
    parser.add_argument("--mailtype", "-mail", default="FAIL", help="Mail type settings. Options: NONE, BEGIN, END, FAIL, REQUEUE, ALL. Default: FAIL. Optional.")
    parser.add_argument("--memory", "-mem", default="8G", help="Memory allocation for SLURM job. Default: 8G. Optional.")
    parser.add_argument("--time", "-t", default="00:15:00", help="Time allocation for SLURM job. Default: 00:15:00. Optional.")
    parser.add_argument('--verbose', '-v', action='store_true', help='Print extra information. Optional.')
    parser.add_argument('--version', '-V', action='version', version=f'%(prog)s {VERSION} ({VERSION_DATE}).')
    args = parser.parse_args()

    # Start the script
    print(f"+ {VERSION_NAME} v{VERSION} ({VERSION_DATE}) +")
    print(f"\nStarting the testing of alternative models on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}.")

    # Check if required arguments are provided
    # if args.interaction == "interaction" and args.interactionparam is None:
    #     print(f"Error: Interaction analysis is requested, but no parameter is provided (see https://www.cog-genomics.org/plink/1.9/assoc#linear).")
    #     parser.print_help()
    #     exit(1)
    required_args = ['phenotypes', 'phenofile', 'covariates', 'glm', 'snp', 'chromosome', 'projectdir', 'outputdir']
    missing_args = [arg for arg in required_args if not getattr(args, arg)]
    if missing_args:
        print(f"Error: The following required arguments are missing: {', '.join(missing_args)}")
        parser.print_help()
        exit(1)

    # Check if project directory and output directory exist
    if not os.path.exists(args.projectdir):
        print(f"Error: Project directory '{args.projectdir}' does not exist.")
        exit(1)
    if not os.path.exists(args.outputdir):
        print(f"Output directory '{args.outputdir}' does not exist. Making it for you.")
        os.makedirs(args.outputdir)

    # Start the timer
    start_time = time.time()
    
    # Get today's date
    today_date = datetime.now()

    # Format the date as yyyymmdd
    formatted_today = today_date.strftime("%Y%m%d")

    # Submit jobs or printing command
    if args.submit:
        submit_jobs(args.phenotypes, args.phenofile, args.covariates, args.glm, args.snp, args.chromosome, args.projectdir, args.outputdir, args.model, args.interaction, args.interactionparam, args.sex, submit=True, mailtype=args.mailtype, memory=args.memory, time=args.time, email=args.email, verbose=args.verbose)
        # can probably be removed
        # if args.model is None:
        #     submit_jobs(args.phenotypes, args.phenofile, args.covariates, args.glm, "", args.snp, args.chromosome, args.projectdir, args.outputdir, args.interaction, args.sex, submit=True, mailtype=args.mailtype, memory=args.memory, time=args.time, email=args.email, verbose=args.verbose)
    else:
        submit_jobs(args.phenotypes, args.phenofile, args.covariates, args.glm, args.snp, args.chromosome, args.projectdir, args.outputdir, args.model, args.interaction, args.interactionparam, args.sex, execute=args.execute, submit=False, verbose=args.verbose)
    # can probably be removed
    # if args.submit:
    #     submit_jobs(args.phenotypes, args.phenofile, args.covariates, args.selection, args.selectioncol, args.glm, args.model, args.snp, args.chr, args.projectdir, args.outputdir, args.sex, args.submit, args.mailtype, args.memory, args.time, args.email, args.verbose)

    # Calculate the elapsed time in seconds
    elapsed_time = time.time() - start_time
    # Convert seconds to a timedelta object
    time_delta = timedelta(seconds=elapsed_time)
    # Extract hours, minutes, seconds, and milliseconds
    hours, remainder = divmod(time_delta.seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    milliseconds = round(time_delta.microseconds / 1000)
    # Print the script execution time in the desired format
    formatted_time = f"{hours} hours, {minutes} minutes, {seconds} seconds, {milliseconds} milliseconds"

    print(f"\nScript executed on {today_date.strftime('%Y-%m-%d')}. Total execution time was {formatted_time} (minus writing time).")

# Run the main function
if __name__ == "__main__":
    main()

# Print the version number
print(f"\n+ {VERSION_NAME} v{VERSION} ({VERSION_DATE}). {COPYRIGHT} +")
print(f"{COPYRIGHT_TEXT}")
# End of file
