# This script contains the helper functions for the R portion of the pipeline.
# It defines the visualization logic using ggplot2.

# 1. Load required R packages
# This is only needed if you run this script by hand,
# in which case, uncomment lines 8 and 9.
# With rixpress, the packages get loaded automatically.
#library(ggplot2)
#library(dplyr)

#-------------------------------------------------------------------------------
# 2. Main Function: Create the Visualization
#-------------------------------------------------------------------------------

#' Create a plot comparing actual vs. predicted output
#'
#' This function takes a data frame with actual and predicted time series data
#' and generates a ggplot visualization.
#'
#' @param predictions_df A data frame containing columns: 'period',
#'   'actual_output', and 'predicted_output'. This data frame will be the
#'   output of the Python XGBoost step.
#' @return A ggplot object.
#'
plot_predictions <- function(predictions_df) {
  # Create the plot object
  p <- ggplot(predictions_df, aes(x = period)) +

    # Add a line for the actual output from the RBC model simulation
    geom_line(
      aes(y = actual_output, color = "Actual (RBC Model)"),
      linewidth = 1
    ) +

    # Add a dashed line for the XGBoost model's predictions
    geom_line(
      aes(y = predicted_output, color = "Predicted (XGBoost)"),
      linetype = "dashed",
      linewidth = 1
    ) +

    # Define custom colors and legend labels
    scale_color_manual(
      name = "Series",
      values = c("Actual (RBC Model)" = "blue", "Predicted (XGBoost)" = "red")
    ) +

    # Add informative labels and a title
    labs(
      title = "XGBoost Prediction of RBC Model Output",
      subtitle = "Forecasting next-quarter output based on current-quarter economic variables",
      x = "Time (Quarters)",
      y = "Output (Log-deviations from steady state)"
    ) +

    # Use a clean theme
    theme_minimal() +

    # Improve legend position
    theme(legend.position = "bottom")

  # Return the final ggplot object
  return(p)
}
