#Rscript to generate plots for the virus contamination analysis
#Emma Thomson 07/01/2024
#MRC-University of Glasgow Centre for Virus Research

# Load necessary libraries
library(ggplot2)

# Find the first .report file
report_files <- list.files(pattern = "\\.report$")
if (length(report_files) == 0) {
    stop("No .report file found.")
}

report_file <- report_files[1] # Use the first .report file
output_pdf_name <- sub("\\.report$", "", report_file) # Remove .report extension for output file name

# Get the list of .common files
common_files <- list.files(pattern = "\\.common$")

# Extract stem names from these files
stem_names <- sub("\\.common$", "", common_files)

# Initialize an empty data frame
data <- data.frame(Stem = character(), Count = integer(), Common = integer(), Percentage = numeric())

# Loop through each stem name and read the corresponding data
for (stem in stem_names) {
    count_data <- read.table(paste0(stem, ".count"), header = FALSE, col.names = c("Count"), colClasses = "integer")
    common_data <- read.table(paste0(stem, ".common"), header = FALSE, col.names = c("Common"), colClasses = "integer")
    percentage_data <- read.table(paste0(stem, ".percentage"), header = FALSE, col.names = c("Percentage"), colClasses = "numeric")

    # Truncate stem name at the first period
    truncated_stem <- sub("\\..*", "", stem)

    # Combine data into one data frame for each stem and append
    data <- rbind(data, data.frame(Stem = truncated_stem, Count = count_data$Count, Common = common_data$Common, Percentage = percentage_data$Percentage))
}

# Split data based on percentage criteria
data_above_50 <- subset(data, Percentage > 50)
data_below_or_equal_50 <- subset(data, Percentage <= 50)

# Define a function to create plots
plot_data <- function(data, title) {
    ggplot(data, aes(x = Stem)) +
        geom_bar(aes(y = Count), stat = "identity", fill = "blue", alpha = 0.6) +
        geom_bar(aes(y = Common), stat = "identity", fill = "red", alpha = 0.6) +
        labs(title = title,
             x = "Sample",
             y = "Counts") +
        theme_minimal() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

# Create plots
plot1 <- plot_data(data_above_50, "GRAPH OF SAMPLES LIKELY TO BE RELIABLE")
plot2 <- plot_data(data_below_or_equal_50, "GRAPH OF SAMPLES OF CONCERN (RECIPIENT READS > DONOR READS)")

# Create a PDF file with the plots based on the report file name
pdf(paste0(output_pdf_name, "_graphs.pdf"), height = 11, width = 8.5)
print(plot1)
print(plot2)
dev.off()

