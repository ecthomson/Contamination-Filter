#Bash script to identify identical viral reads in samples from the same run - to look for evidence of cross-contamination
#Emma Thomson 09/01/2024 emma.thomson@glasgow.ac.uk
#Input files are .sam - these should all be in the same folder
#Identify the virus both by name and accession number - the accession number should be in the sam file name
#Written in bash script and awk

# Modified Bash script to identify identical viral reads in samples from the same run
# Now reads from a tab-delimited file containing virus names and accession numbers

# Clear the screen and print the introductory message
clear
#!/bin/bash
# Modified Bash script to identify identical viral reads in samples from the same run
# Now accepts a tab-delimited file as a command-line argument

# Check if the input file is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <tab-delimited-filename>"
    exit 1
fi

# The input file is the first argument
INPUT_FILE="$1"

echo "Cross-contamination detector script initiating..."
echo "Written by Emma Thomson"
echo "MRC-University of Glasgow Centre for Virus Research"
echo "9th January 2024"
echo ""

# Read the file containing virus names and accession numbers
while IFS=$'\t' read -r virus accession
do
    echo "Processing $virus with accession number $accession..."

    # Count the number of .sam files for the current virus/accession number
    sam_count=$(ls *"$accession"*.sam | wc -l)
    echo "Found $sam_count .sam files for $virus ($accession)"

#Extract the mapped sequences as fasta from sam file
# Define function "extract_sequences"
extract_sequences() {
    if [ -z "$1" ]; then
        echo "Usage: extract_sequences <file.sam>"
        return 1
    fi

    awk 'BEGIN{FS="\t"}$1!~/^@/ && $4!=0 {print ">"$1"\n"$10}' "$1"
}

# Iterate over each SAM file and apply the extract_sequences function
echo "Extracting fasta from sam files"
for sam in *"$accession"*.sam; do
    extract_sequences "$sam" > "${sam}.samfa"
done

#Delete empty .samfa files
echo "Deleting empty .samfa files"
find -type f -name "*.samfa" -empty -delete

# Count the generated .samfa files that contain data
samfa_count=$(ls *.samfa | wc -l)
echo "$samfa_count" "samfa files created"

#Identify how many sequences there are in each file and create new files containing counts
for count in *.samfa; do (grep ">" $count| wc -l >$count\.count); done

#Create sorted sequence files and remove fasta ">" line
for sorted in *.samfa; do (grep -v ">" $sorted | sort > $sorted\.sorted); done

#Now loop through all the files and identify unique and non-unique reads

# Populate file_list with all sorted .samfa files in the current directory
file_list=(*"$accession"*samfa.sorted)

# Check if there are at least two files to compare
if [ ${#file_list[@]} -lt 2 ]; then
    echo "Not enough files to compare. Need at least two .samfa.sorted files."
    exit 1
fi

# Loop through each file
for file_i in "${file_list[@]}"; do
    total_common=0
    detail_content=""

    # Compare with other files
    for file_j in "${file_list[@]}"; do
        # Skip if it's the same file
        if [ "$file_i" == "$file_j" ]; then
            continue
        fi

        # Count common lines
        common_lines=$(comm -12 "$file_i" "$file_j" | wc -l)
        total_common=$((total_common + common_lines))

        # Append to detail content only if there are common lines
        if [ "$common_lines" -gt 0 ]; then
            detail_content+="$file_j: $common_lines\n"
        fi
    done

    # Create .common and .detail files only if there is at least one common line
    if [ "$total_common" -gt 0 ]; then
        echo "$total_common" > "$file_i.common"
        echo -e "$detail_content" > "$file_i.detail"
    fi
done

rename 's/sorted\.common/common/g' *sorted.common
rename 's/sorted\.detail/detail/g' *sorted.detail

# Loop over files with .common extension
for count_file in *.common; do
    # Extract the stem name by removing the .common extension
    stem_name="${count_file%.common}"

    # Check if corresponding .count file exists
    if [[ -f "$stem_name.count" ]]; then
        # Read values from the .count and .common files
        count_value=$(cat "$stem_name.count")
        common_value=$(cat "$stem_name.common")

        # Check if count_value is not zero to avoid division by zero
        if [ "$count_value" -ne 0 ]; then
            # Perform the calculation
            unique_percentage=$(( ($count_value - $common_value) * 100 / $count_value ))

            # Output the result to a new file with the stem name and .percentage
            echo "$unique_percentage" > "$stem_name.percentage"
        else
            echo "Total count for $stem_name is zero, cannot calculate percentage." > "$stem_name.percentage"
        fi
    else
        echo "No corresponding .count file found for $stem_name" > "$stem_name.percentage"
    fi
done

#Report 
echo "Generating report"
report=$virus\_$accession\.report
echo "
REPORT - VIRUS: "$virus" ACCESSION: "$accession"" "$DATE" > $report
samfa_no=$(ls *.samfa | wc -l)
echo "
FILES ANALYSED: "$samfa_no" ">>$report
#ls *.samfa >>$report
echo "Files containing shared sequences from the same run are listed below" >>$report
common_no=$(ls *.common | wc -l)
echo "
TOTAL FILE COUNT WITH COMMON SEQUENCES:" "$common_no" >> $report
echo "Files with shared sequences are listed below" >>$report
ls *.common | sed 's/\.common//g'>>$report
echo "
PERCENTAGE UNIQUE READS" >> $report
for percentage in *.percentage; do echo "
FILENAME:">>$report; ls "$percentage">>$report; echo "PERCENTAGE:">>$report; cat "$percentage">>$report; echo "TOTAL READS:">>$report; cat "$(ls $percentage|sed 's/\.percentage//g').count" >>$report; echo "COMMON READS:" >> $report; cat "$(ls $percentage|sed 's/\.percentage//g').common">>$report; echo "FILES WITH IDENTICAL READS:">>$report; cat "$(ls $percentage | sed 's/\.percentage//g').detail">>$report ; done

sed -i 's/\.samfa\.sorted//g' $report
sed -i "s/\: /\:/g" $report
sed -i -e ':a' -e '/:$/{N; ba}' -e 's/:\n/: /' $report


#Put results in a folder labelled with accession and virus
mkdir $virus\_$accession > /dev/null 2>&1
mv *"$accession"*common $virus\_$accession/
mv *"$accession"*detail $virus\_$accession/
mv *"$accession"*count $virus\_$accession/
mv *"$accession"*percentage $virus\_$accession/

#Creat a plot of the results using the contamination_chart.R script (downloaded with this script)
cp contamination_chart.R $virus\_$accession/
Rscript $virus\_$accession/contamination_chart.R > /dev/null 2>&1

#Report generation
mv $report $virus\_$accession/
mv *graphs.pdf $virus\_$accession/

echo "Cross-contamination check is complete. You can find your files in the "$virus\_$accession/" folder, including a report appended by .report."


done < "$INPUT_FILE"

echo "Batch processing complete."

