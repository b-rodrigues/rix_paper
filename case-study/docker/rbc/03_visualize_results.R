# ==============================================================================
# 03_visualize_results.R
#
# Loads model predictions and creates a visualization.
#
# Usage: Rscript 03_visualize_results.R <input_path> <output_path>
# Example: Rscript 03_visualize_results.R data/predictions.arrow plots/output_plot.png
# ==============================================================================

# Load required packages
library(arrow)
library(ggplot2)
library(dplyr)

# Source the helper function containing the plotting logic.
source("functions/functions.R")

# Get command-line arguments.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
  stop(
    "Usage: Rscript 03_visualize_results.R <input_path> <output_path>",
    call. = FALSE
  )
}

input_path <- args[1]
output_path <- args[2]

# --- Load Data ---
cat("Loading prediction data from:", input_path, "\n")
predictions_df <- read_feather(input_path)

# --- Generate Plot ---
cat("Generating plot...\n")
output_plot <- plot_predictions(predictions_df)

# --- Save Plot ---
cat("Saving plot to:", output_path, "\n")
ggsave(
  output_path,
  plot = output_plot,
  width = 10,
  height = 6,
  dpi = 300
)

cat("R script finished successfully.\n")
