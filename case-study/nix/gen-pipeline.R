# This script defines and orchestrates the entire reproducible analytical pipeline
# using the {rixpress} package.

library(rixpress)

# Define the full pipeline as a list of derivations and pipe it to rxp_populate()
# to generate the Nix build instructions and execute the pipeline.
list(
  # STEP 0: Define RBC Model Parameters as Derivations
  # This makes the parameters an explicit part of the pipeline.
  # Changing a parameter will cause downstream steps to rebuild.
  rxp_jl(alpha, 0.3), # Capital's share of income
  rxp_jl(beta, 1 / 1.01), # Discount factor
  rxp_jl(delta, 0.025), # Depreciation rate
  rxp_jl(rho, 0.95), # Technology shock persistence
  rxp_jl(sigma, 1.0), # Risk aversion (log-utility)
  rxp_jl(sigma_z, 0.01), # Technology shock standard deviation

  # STEP 1: Julia - Simulate a Real Business Cycle (RBC) model.
  # This derivation runs our Julia script to generate the source data.
  rxp_jl(
    name = simulated_rbc_data,
    expr = "simulate_rbc_model(alpha, beta, delta, rho, sigma, sigma_z)",
    user_functions = "functions/functions.jl", # The file containing the function
    encoder = "arrow_write" # The function to use for saving the output
  ),

  # STEP 2.1: Python - Prepare features (lagging data)
  rxp_py(
    name = processed_data,
    expr = "prepare_features(simulated_rbc_data)",
    user_functions = "functions/functions.py",
    # Decode the Arrow file from Julia into a pandas DataFrame
    decoder = "feather.read_feather"
    # Note: No encoder needed here. {rixpress} will use pickle by default
    # to pass the DataFrame between Python steps.
  ),

  # STEP 2.2: Python - Split data into training and testing sets
  rxp_py(
    name = X_train,
    expr = "get_X_train(processed_data)",
    user_functions = "functions/functions.py"
  ),

  rxp_py(
    name = y_train,
    expr = "get_y_train(processed_data)",
    user_functions = "functions/functions.py"
  ),

  rxp_py(
    name = X_test,
    expr = "get_X_test(processed_data)",
    user_functions = "functions/functions.py"
  ),

  rxp_py(
    name = y_test,
    expr = "get_y_test(processed_data)",
    user_functions = "functions/functions.py"
  ),

  # STEP 2.3: Python - Train the model
  rxp_py(
    name = trained_model,
    expr = "train_model(X_train, y_train)",
    user_functions = "functions/functions.py"
  ),

  # STEP 2.4: Python - Make predictions
  rxp_py(
    name = model_predictions,
    expr = "make_predictions(trained_model, X_test)",
    user_functions = "functions/functions.py"
  ),

  # STEP 2.5: Python - Format final results for R
  rxp_py(
    name = predictions,
    expr = "format_results(y_test, model_predictions)",
    user_functions = "functions/functions.py",
    # We need an encoder here to save the final DataFrame as an Arrow file
    # so the R step can read it.
    encoder = "save_arrow"
  ),

  # STEP 3: R - Visualize the predictions from the Python model.
  # This final derivation depends on the output of the Python step.
  rxp_r(
    name = output_plot,
    expr = plot_predictions(predictions), # The function to call from functions.R
    user_functions = "functions/functions.R",
    # Specify how to load the upstream data (from Python) into R.
    decoder = arrow::read_feather
  ),

  # STEP 4: Quarto - Compile the final report.
  rxp_qmd(
    name = final_report,
    additional_files = "_rixpress",
    qmd_file = "readme.qmd"
  )
) |>
  rxp_populate(
    py_imports = c(
      pandas = "import pandas as pd",
      pyarrow = "import pyarrow.feather as feather",
      sklearn = "from sklearn.model_selection import train_test_split",
      xgboost = "import xgboost as xgb"
    ),
    project_path = ".", # The root of our project
    build = FALSE # Set to TRUE to execute the pipeline immediately
  )
