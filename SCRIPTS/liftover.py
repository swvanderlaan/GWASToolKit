#!/usr/bin/env python3

# Change log
# * v1.0.0 2024-04-11: Initial version.
# Version information
VERSION_NAME = 'liftOver'
VERSION = '1.0.0'
VERSION_DATE = '2024-04-19'
COPYRIGHT = 'Copyright 1979-2024. Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com | https://vanderlaanand.science.'
COPYRIGHT_TEXT = f'\nThe MIT License (MIT). \n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and \nassociated documentation files (the "Software"), to deal in the Software without restriction, \nincluding without limitation the rights to use, copy, modify, merge, publish, distribute, \nsublicense, and/or sell copies of the Software, and to permit persons to whom the Software is \nfurnished to do so, subject to the following conditions: \n\nThe above copyright notice and this permission notice shall be included in all copies \nor substantial portions of the Software. \n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, \nINCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR \nPURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS \nBE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, \nTORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE \nOR OTHER DEALINGS IN THE SOFTWARE. \n\nReference: http://opensource.org.'

import sys
from tqdm import tqdm
import os
import argparse
from pyliftover import LiftOver
from argparse import RawTextHelpFormatter
import shutil
import time
from datetime import datetime
from datetime import timedelta
import subprocess

# Function to convert coordinates
# convert_coordinates(args.input, args.output_dir, args.pos_type, args.build, args.verbose)
def convert_coordinates(input_file, output_dir, pos_type, build, verbose=False):
    # Initialize LiftOver object based on build
    if build == 'b37_to_b38':
        lo = LiftOver('hg19', 'hg38')
    elif build == 'b38_to_b37':
        lo = LiftOver('hg38', 'hg19')
    elif build == 'b17_to_b37':
        lo = LiftOver('hg17', 'hg19')
    elif build == 'b17_to_b38':
        lo = LiftOver('hg17', 'hg38')
    elif build == 'b18_to_b37':
        lo = LiftOver('hg18', 'hg19')
    elif build == 'b18_to_b38':
        lo = LiftOver('hg18', 'hg38')
    else:
        print("Invalid build option. Supported options are 'b37_to_b38', 'b38_to_b37', 'b17_to_b37', 'b17_to_b38', 'b18_to_b37', 'b18_to_b38'.")
        return

    # Check if project directory and output directory exist
    if not os.path.exists(output_dir):
        print(f"Error: Project directory '{output_dir}' does not exist.")
        exit(1)
    if not os.path.exists(output_dir):
        print(f"Output directory '{output_dir}' does not exist. Making it for you.")
        os.makedirs(output_dir)

    # Output filename
    output_file = os.path.join(output_dir, f'lifover.{build}.converted_coordinates.txt')
    failed_log_file = os.path.join(output_dir, f'lifover.{build}.failed_variants.log')

    successful_variants = 0
    failed_variants = 0

    with open(input_file, 'r') as f_in, open(output_file, 'w') as f_out, open(failed_log_file, 'w') as f_failed_log_file:
        f_failed_log_file.write(f"+ {VERSION_NAME} v{VERSION} +\n")
        f_failed_log_file.write(f"Listing variants that failed lift over from {build}.\n")
        f_failed_log_file.write(f"\nRSID\tChromosome\tPosition\n")

        if verbose: 
            print(f"- writing converted coordinates to : {output_file}")
            print(f"- writing failed variants to: {failed_log_file}")
            if pos_type == 0:
                print(f"- converting to 0-based; adding strand and conversion chain score to output file.\n")
            else:
                print(f"- converting to 1-based.\n")
        # Write the header to the output file
        if pos_type == 0:
            f_out.write(f"RSID\tChromosome\tPosition\tStrand\tConversion_Chain_Score\n")
        else:
            f_out.write(f"RSID\tChromosome\tPosition\n")

        # Skip the header line if it exists
        header_line = next(f_in, None)
        if header_line:
            if header_line.strip().lower().startswith(('snpid', 'rsid', 'variant_id', 'snp', 'variantid', 'dbsnpid')):  # Adjust based on actual header
                if verbose: 
                    print(f"Header in {input_file}. Skipping.")
                # Skip the header line
                pass
            else:
                if verbose:
                    print(f"No header in {input_file}.")
                # Not a header line, process it
                parts = header_line.strip().split()
                snpid, chromosome, position = parts[0], parts[1], int(parts[2])
                # Convert coordinates
                # check lifover output
                # https://github.com/konstantint/pyliftover/blob/master/pyliftover/liftover.py#L66
                # Returns a list of possible conversions for a given chromosome position. The list may be empty 
                # (no conversion), have a single element (unique conversion), or several elements (position 
                # mapped to several chains). The list contains tuples (target_chromosome, target_position, 
                # target_strand, conversion_chain_score), where conversion_chain_score is the "alignment score" 
                # field specified at the chain used to perform conversion. If there are several possible conversions, 
                # they are sorted by decreasing conversion_chain_score.
                if verbose:
                    print(f"Processing the remaining lines. Converting coordinates.")
                new_coords = lo.convert_coordinate(chromosome, position) 
                # If conversion is successful, write to output
                if new_coords:
                    if verbose:
                        print(f"- success for {chromosome}:{position}.")
                    new_chr, new_pos, new_strand, new_conversion_score = new_coords[0]
                    # Strip 'chr' prefix if necessary
                    if build == 'b38_to_b37' or build == 'b17_to_b37' or build == 'b18_to_b37':
                        new_chr_stripped = new_chr.lstrip('chr')  # Strip 'chr' prefix
                    else:
                        new_chr_stripped = new_chr
                    # Write to output file
                    if pos_type == 0:
                        new_pos -= 1  # Convert to 0-based
                        print(f"- success for {chromosome}:{position} - found this: {new_coords}.")
                        f_out.write(f"{snpid}\t{new_chr_stripped}\t{new_pos}\t{new_strand}\t{new_conversion_score}\n")
                    else:
                        f_out.write(f"{snpid}\t{new_chr_stripped}\t{new_pos}\n")
                    successful_variants += 1
                else:
                    print(f"- failed for {chromosome}:{position}.")
                    f_failed_log_file.write(f"{snpid}\t{chromosome}\t{position}\n")
                    failed_variants += 1
        
        # Process the remaining lines
        if verbose:
            print(f"Processing the remaining lines. Converting coordinates.")
                
        # # Initialize tqdm progress bar
        # progress_bar = tqdm(desc="Converting coordinates", total=sum(1 for line in f_in), file=sys.stdout)

        for line in f_in:
            parts = line.strip().split()
            snpid, chromosome, position = parts[0], parts[1], int(parts[2])
            
            # Convert coordinates
            new_coords = lo.convert_coordinate(chromosome, position)

            # If conversion is successful, write to output
            if new_coords:
                new_chr, new_pos, new_strand, new_conversion_score = new_coords[0]
                # Strip 'chr' prefix if necessary
                if build == 'b38_to_b37' or build == 'b17_to_b37' or build == 'b18_to_b37':
                    new_chr_stripped = new_chr.lstrip('chr')  # Strip 'chr' prefix
                else:
                    new_chr_stripped = new_chr
                # Write to output file
                if pos_type == 0:
                    new_pos -= 1  # Convert to 0-based
                    print(f"- success for {chromosome}:{position} - found this: {new_coords}.")
                    f_out.write(f"{snpid}\t{new_chr_stripped}\t{new_pos}\t{new_strand}\t{new_conversion_score}\n")
                else:
                    f_out.write(f"{snpid}\t{new_chr_stripped}\t{new_pos}\n")
                successful_variants += 1
            else:
                print(f"- failed for {chromosome}:{position}.")
                f_failed_log_file.write(f"{snpid}\t{chromosome}\t{position}\n")
                failed_variants += 1
            
            #     # Update progress bar
            #     progress_bar.update(1)
            # # Close progress bar
            # progress_bar.close()
        # Write the total number of failed variants to the failed variants log file
        f_failed_log_file.write(f"\nTotal number of failed variants: {failed_variants}. No further failed variants.\n")
    return successful_variants, failed_variants

def main():
    parser = argparse.ArgumentParser(description=f'''
+ {VERSION_NAME} v{VERSION} +

This script converts genomic coordinates between genome builds using the `pyliftover` package.
The input `--input_file` file should be a tab-separated file with two columns: chromosome and position. 
The output file will be a tab-separated file with two columns: chromosome and position. By default, 
the output file will be named `converted_coordinates.txt` and saved in the current directory. Optionally,
the output directory can be specified using the `--output_dir` argument.

By default the input is expected to be b37 and positions will be lift over to b38. Optionally, the build can be
specified using the `--build` argument. Supported options are 'b37_to_b38' and 'b38_to_b37'. By default,
the position type is 1-based. Optionally, the position type can be specified using the `--pos_type` argument.

By default the script will log the failed variants to a file named `failed_variants.log` in the output directory. 
By default, the script will not log the conversion process. Optionally, the script can log the conversion process
using the `--log` argument. 

Optionally, the script can print extra information using the `--verbose` argument.

Example usage:
    python liftover.py --input_file input.txt --output_dir /path/to/output_dir --build b37_to_b38 --pos_type 1 --log --verbose

        ''',
        epilog=f'''
+ {VERSION_NAME} v{VERSION}. {COPYRIGHT} \n{COPYRIGHT_TEXT}+''', 
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('--input', '-i', type=str, help='Path to input tab-delimited textfile with 3 columns: snpid chr bp.')
    parser.add_argument('--output_dir', '-o', type=str, default=os.getcwd(), help='Output directory. Default is current directory.')
    parser.add_argument('--pos_type', '-p', type=int, default=1, choices=[0, 1], help='Position type (0 for 0-based, 1 for 1-based). Default is 1.')
    parser.add_argument('--build', '-b', type=str, choices=['b37_to_b38', 'b38_to_b37', 'b17_to_b37', 'b17_to_b38', 'b18_to_b37', 'b18_to_b38'], help='Build for conversion. Default is b37_to_b38.')
    parser.add_argument('--log', action='store_true', help='Enable logging. Optional.')
    parser.add_argument('--verbose', '-v', action='store_true', help='Print extra information. Optional.')
    parser.add_argument('--version', '-V', action='version', version=f'%(prog)s {VERSION} ({VERSION_DATE}).')

    args = parser.parse_args()
    # Start the script
    print(f"+ {VERSION_NAME} v{VERSION} ({VERSION_DATE}) +")
    print(f"\nStarting liftOver job {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}.")
    # Check if build is provided
    if args.build is None:
        print(f"Note. Build was not provided; assuming b37 to b38 liftover.\n")
        args.build = 'b37_to_b38'
    else:
        print(f"Build was provided: {args.build}.\n")

    # Check if required arguments are provided
    # if args.interaction == "interaction" and args.interactionparam is None:
    #     print(f"Error: Interaction analysis is requested, but no parameter is provided (see https://www.cog-genomics.org/plink/1.9/assoc#linear).")
    #     parser.print_help()
    #     exit(1)
    required_args = ['input']
    missing_args = [arg for arg in required_args if not getattr(args, arg)]
    if missing_args:
        print(f"Error. The following required arguments are missing: {', '.join(missing_args)}.")
        print(f"Please provide the required arguments, as shown below.\n")
        parser.print_help()
        exit(1)
    # Start the timer
    start_time = time.time()
    
    # Get today's date
    today_date = datetime.now()

    # Format the date as yyyymmdd
    formatted_today = today_date.strftime("%Y%m%d")

    # Run the conversion
    if args.verbose:
        print(f"Converting coordinates using the following parameters:")
        print(f"- input: {args.input} (data output directory is {args.output_dir})")
        if args.build == 'b38_to_b37' or args.build == 'b17_to_b37' or args.build == 'b18_to_b37':
            print(f"- build {args.build}; stripping 'chr' prefix from chromosome names")
        else:
            print(f"- build: {args.build}")
        print(f"- position-type: {args.pos_type}")
    successful_variants, failed_variants = convert_coordinates(args.input, args.output_dir, args.pos_type, args.build, args.verbose)

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
    print(f"Successful variants: {successful_variants}, Failed variants: {failed_variants}")

    if args.log:
        # Create a log file
        log_file = os.path.join(args.output_dir, f'lifover.{args.build}.log')
        with open(log_file, 'w') as f_log_file:
            f_log_file.write(f"+ {VERSION_NAME} v{VERSION} +\n") 
            f_log_file.write(f"Start time: {start_time}\n") 
            f_log_file.write(f"liftOver job settings:")
            f_log_file.write(f"- input: {args.input} (data output directory is {args.output_dir})\n")
            if args.build == 'b38_to_b37' or args.build == 'b17_to_b37' or args.build == 'b18_to_b37':
                f_log_file.write(f"- build {args.build}; stripping 'chr' prefix from chromosome names\n")
            else:
                f_log_file.write(f"- build: {args.build}\n")
            f_log_file.write(f"- position-type: {args.pos_type}\n")
            f_log_file.write(f"\nScript executed on {today_date.strftime('%Y-%m-%d')}. Total execution time was {formatted_time} (minus writing time).")
            f_log_file.write(f"Successful variants: {successful_variants}. Failed variants: {failed_variants}.")
    # Write the execution time to the failed variants log file
    failed_log_file = os.path.join(args.output_dir, f'lifover.{args.build}.failed_variants.log')
    with open(failed_log_file, 'a') as f_failed_log_file:
        f_failed_log_file.write(f"\nScript executed on {today_date.strftime('%Y-%m-%d')}. Total execution time was {formatted_time} (minus writing time).")

if __name__ == "__main__":
    main()

# Print the version number
print(f"\n+ {VERSION_NAME} v{VERSION} ({VERSION_DATE}). {COPYRIGHT} +")
print(f"{COPYRIGHT_TEXT}")
# End of file
