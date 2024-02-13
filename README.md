Battch Cross-Contamination Detector
This Bash script, developed by Emma Thomson, identifies identical viral reads across samples from the same sequencing run to detect potential cross-contamination. It processes .sam files, extracting and analyzing mapped sequences to identify commonalities that indicate contamination.

Features
Processes multiple .sam files based on virus names and accession numbers.
Extracts mapped sequences and converts them to fasta format.
Identifies unique and non-unique reads across samples.
Generates detailed reports, including the percentage of unique reads.
Prerequisites
Unix-like environment (Linux, macOS)
AWK for text processing
R and specific R packages for generating contamination charts
Installation
Download batch-cross-contamination-detector.sh and contamination_chart.R.
Ensure executable permissions: chmod +x batch-cross-contamination-detector.sh.
./batch-cross-contamination-detector.sh <tab-delimited-filename>
The input file should contain virus names and accession numbers, separated by tabs.
Input Format
The expected input is a tab-delimited file with each line containing a virus name and its corresponding accession number.
VirusName1    AccessionNumber1
VirusName2    AccessionNumber2
Output
The script outputs a folder named <VirusName>_<AccessionNumber> containing: .common files indicating shared sequences
Detailed reports and charts of contamination analysis
Reporting Issues
For any issues or questions, please contact Emma Thomson at emma.thomson@glasgow.ac.uk.

Acknowledgments
Thanks to the MRC-University of Glasgow Centre for Virus Research for support and resources.


