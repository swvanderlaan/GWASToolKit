#!/usr/bin/env python3

# Change log
# * v1.0.1 2024-04-12: Fixed issue with output writing; removed trailing spaces and replaced tabs with spaces. Added phenotype column to output files.
# * v1.0.0 2024-04-12: Initial version.
# Version information
VERSION_NAME = 'Summarize AltModels'
VERSION = '1.0.1'
VERSION_DATE = '2024-04-12'
COPYRIGHT = 'Copyright 1979-2024. Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com | https://vanderlaanand.science.'
COPYRIGHT_TEXT = f'\nThe MIT License (MIT). \n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and \nassociated documentation files (the "Software"), to deal in the Software without restriction, \nincluding without limitation the rights to use, copy, modify, merge, publish, distribute, \nsublicense, and/or sell copies of the Software, and to permit persons to whom the Software is \nfurnished to do so, subject to the following conditions: \n\nThe above copyright notice and this permission notice shall be included in all copies \nor substantial portions of the Software. \n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, \nINCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR \nPURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS \nBE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, \nTORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE \nOR OTHER DEALINGS IN THE SOFTWARE. \n\nReference: http://opensource.org.'

# Import modules
import argparse
from argparse import RawTextHelpFormatter
import os
import time
from datetime import datetime
from datetime import timedelta
import shutil
import tarfile

# Define default values
default_output_dir = os.getcwd()
# phenotypes_logistic = ["Calcification", "Collagen", "Fat10", "Fat40", "IPH"]
# phenotypes_linear = ["SMC_rankNorm", "MAC_rankNorm", "Neutrophils_rankNorm", "MastCells_rankNorm", "VesselDensity_rankNorm", "Plaque_Vulnerability_Index"]

# Function to concatenate logistic regression results
def concatenate_logistic_results(snp_format, phenotypes, output_dir, verbose):
    # Create the output file
    output_file = os.path.join(output_dir, f"logistic.chr{snp_format}.results.txt")

    if verbose:
        print(f"- creating summary results file [{output_file}], and adding results for...")
    with open(output_file, "w") as f:
        f.write("Phenotype CHROM POS ID REF ALT PROVISIONAL_REF? A1 OMITTED A1_FREQ Firth? TEST OBS_CT OR LOG(OR)_SE Z_STAT P ERRCODE\n")
        for p in phenotypes:
            if verbose:
                print(f"- {p}")
            file_name = f"logistic_chr{snp_format}_{p}.{p}.glm.logistic.hybrid"
            with open(file_name) as infile:
                next(infile)  # Skip header
                for line in infile:
                    # Replace tabs with spaces
                    line = p + " " + line.strip().replace("\t", " ")
                    f.write(line + "\n")

# Function to concatenate linear regression results
def concatenate_linear_results(snp_format, phenotypes, output_dir, verbose):
    # Create the output file
    output_file = os.path.join(output_dir, f"linear.chr{snp_format}.results.txt")

    if verbose:
        print(f"- creating summary results file [{output_file}], and adding results for...")
    with open(output_file, "w") as f:
        f.write("Phenotype CHROM POS ID REF ALT PROVISIONAL_REF? A1 OMITTED A1_FREQ TEST OBS_CT BETA SE T_STAT P ERRCODE\n")
        for p in phenotypes:
            if verbose:
                print(f"- {p}")
            file_name = f"linear_chr{snp_format}_{p}.{p}.glm.linear"
            with open(file_name) as infile:
                next(infile)  # Skip header
                for line in infile:
                    # Replace tabs with spaces
                    line = p + " " + line.strip().replace("\t", " ")
                    f.write(line + "\n")

# Function to create tar.gz files
def create_tar_file(file_name, raw_result, raw_result_log, output_dir, verbose=False):
    if verbose: 
        print(f"- processing {raw_result} and {raw_result_log}")
    tar_file_path = os.path.join(output_dir, f"{file_name}.tar.gz")
    with tarfile.open(tar_file_path, "w:gz") as tar:
        tar.add(raw_result)
        tar.add(raw_result_log)

    # Remove the original files
    if verbose:
        print(f"- archived raw results; removing input files")
    os.remove(raw_result)
    os.remove(raw_result_log)

# Define main function
def main():
    parser = argparse.ArgumentParser(description=f'''
+ {VERSION_NAME} v{VERSION} +

This script will concatenate the results of the logistic or linear regression models (`--glm`)
for a given SNP (`--snp`) and a list of phenotypes (`--phenotypes`). The results will be 
written to a single file in the output directory (`--output_dir`); by default the current
working directory. The script will also create `.tar.gz` files for the raw results of the
logistic or linear regression models. The raw results are the files with the extension
`.glm.logistic.hybrid` or `.glm.linear` and the log files with the extension `.log`

Use the `--verbose` flag to print extra information.

To get more information on the script, please use the `--help` flag. The `--version` flag will provide
you with the version information.

Example usage:
python alt_models_summarize.py --snp 16:12345 --glm --phenotypes Calcification Collagen Fat10 Fat40 IPH --output_dir results
        ''',
        epilog=f'''
+ {VERSION_NAME} v{VERSION}. {COPYRIGHT} \n{COPYRIGHT_TEXT}+''', 
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("--snp", "-s", help="Specify the SNP in the format 16:12345")
    parser.add_argument("--glm", "-g", choices=["logistic", "linear"], help="Concatenate linear regression results.")
    parser.add_argument("--phenotypes", "-p", nargs="+", help="List of phenotypes. For example: 'phenotype1 phenotype2 phenotype3'.")
    parser.add_argument("--output_dir", "-o", default=default_output_dir, help="Output directory for results")
    parser.add_argument('--verbose', '-v', action='store_true', help='Print extra information. Optional.')
    parser.add_argument('--version', '-V', action='version', version=f'%(prog)s {VERSION} ({VERSION_DATE}).')

    args = parser.parse_args()

    # Start the script
    print(f"+ {VERSION_NAME} v{VERSION} ({VERSION_DATE}) +")
    print(f"\nSummarizing alternative models on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}.")

    # Check if required arguments are provided
    required_args = ['snp', 'glm', 'phenotypes']
    missing_args = [arg for arg in required_args if not getattr(args, arg)]
    if missing_args:
        print(f"ERROR. The following required arguments are missing, but are required: {', '.join(missing_args)}")
        parser.print_help()
        exit(1)

    # Start the timer
    start_time = time.time()
    
    # Get today's date
    today_date = datetime.now()

    # Format the date as yyyymmdd
    formatted_today = today_date.strftime("%Y%m%d")

    # Convert SNP format to chr16-12345
    snp_format = args.snp.replace(":", "-")

    # Check if output directory exists
    if not os.path.exists(args.output_dir):
        print(f"Output directory '{args.output_dir}' does not exist. Making it for you.")
        os.makedirs(args.output_dir)
    if args.verbose:
        print(f"Output directory is '{args.output_dir}'.")

    # Concatenate logistic regression results
    if args.glm == "logistic":
        if args.verbose:
            print(f"Summarizing logistic regression results for SNP {snp_format} and phenotypes {args.phenotypes}.")
        concatenate_logistic_results(snp_format, args.phenotypes, args.output_dir, args.verbose)
        if args.verbose:
            print(f"Creating tar.gz files for logistic regression results.")
        for p in args.phenotypes:
            if args.verbose:
                print(f"Adding raw results to logistic_chr{snp_format}.{p}.tar.gz")
            create_tar_file(f"logistic_chr{snp_format}_{p}", f"logistic_chr{snp_format}_{p}.{p}.glm.logistic.hybrid", f"logistic_chr{snp_format}_{p}.log", args.output_dir, args.verbose)
    # Concatenate linear regression results
    elif args.glm == "linear":
        if args.verbose:
            print(f"Summarizing linear regression results for SNP {snp_format} and phenotypes {args.phenotypes}.")
        concatenate_linear_results(snp_format, args.phenotypes, args.output_dir, args.verbose)
        if args.verbose:
            print(f"Creating tar.gz files for linear regression results.")
        for p in args.phenotypes:
            if args.verbose:
                print(f"Adding raw results to linear_chr{snp_format}.{p}.tar.gz")
            create_tar_file(f"linear_chr{snp_format}_{p}", f"linear_chr{snp_format}_{p}.{p}.glm.linear", f"linear_chr{snp_format}_{p}.log", args.output_dir, args.verbose)
    else:
        print(f"ERROR. The --glm argument should be either 'logistic' or 'linear'.")
        parser.print_help()
        exit(1)
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

    # Print the total execution time
    print(f"\nScript executed on {today_date.strftime('%Y-%m-%d')}. Total execution time was {formatted_time} (minus writing time).")

# Run the main function
if __name__ == "__main__":
    main()

# Print the version number
print(f"\n+ {VERSION_NAME} v{VERSION} ({VERSION_DATE}). {COPYRIGHT} +")
print(f"{COPYRIGHT_TEXT}")
# End of file