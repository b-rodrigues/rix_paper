# ==============================================================================
# 02_train_model.py
#
# Loads simulated data, trains an XGBoost model, and saves predictions.
#
# Usage: python 02_train_model.py <input_path> <output_path>
# Example: python 02_train_model.py data/simulated_rbc_data.arrow data/predictions.arrow
# ==============================================================================

import sys
import pandas as pd
import pyarrow.feather as feather
import xgboost as xgb
from functions.functions import * # Import all helper functions

def main():
    # Check for correct command-line arguments.
    if len(sys.argv) != 3:
        print("Usage: python 02_train_model.py <input_path> <output_path>")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    # --- Load Data ---
    print(f"Loading simulated data from: {input_path}")
    simulated_df = feather.read_feather(input_path)

    # --- Feature Engineering ---
    print("Preparing features...")
    processed_df = prepare_features(simulated_df)

    # --- Data Splitting ---
    print("Splitting data into training and testing sets...")
    X_train = get_X_train(processed_df)
    y_train = get_y_train(processed_df)
    X_test = get_X_test(processed_df)
    y_test = get_y_test(processed_df)

    # --- Model Training ---
    print("Training XGBoost model...")
    model = train_model(X_train, y_train)

    # --- Prediction ---
    print("Making predictions on the test set...")
    predictions = make_predictions(model, X_test)

    # --- Format and Save Results ---
    print("Formatting and saving results...")
    results_df = format_results(y_test, predictions)
    save_arrow(results_df, output_path)

    print(f"Python script finished. Predictions saved to: {output_path}")

if __name__ == "__main__":
    main()
