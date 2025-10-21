#!/usr/bin/env bash
#
# This script sets up and runs a reproducible, polyglot data science pipeline.
# It requires Nix to be installed on your system (macOS or Linux).
# For installation instructions, visit: https://nixos.org/download.html

set -e # Exit immediately if a command exits with a non-zero status.

if ! command -v nix-shell &> /dev/null; then
    echo -e "${RED}Error: Nix is not installed or not in your PATH.${NC}"
    echo "This script requires Nix to create a reproducible environment."
    echo "Please install it using the recommended Determinate Systems installer:"
    echo -e "${BLUE}https://determinate.systems/posts/determinate-nix-installer${NC}"
    exit 1
fi

# --- Style and Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper function to run commands with a spinner ---
run_with_spinner() {
    local cmd="$1"
    local message="$2"
    
    # Run the command in the background, redirecting all output
    eval "$cmd" > /tmp/spinner.log 2>&1 &
    local pid=$!

    # Animate spinner
    local spin='-\|/'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${YELLOW}%s${NC} %s" "${spin:$i:1}" "$message"
        sleep .1
    done

    # Wait for the command to finish and get its exit code
    wait $pid
    local exit_code=$?

    # Check the exit code and print final status
    if [ $exit_code -eq 0 ]; then
        printf "\r${GREEN}✓${NC} %s\n" "$message"
    else
        printf "\r${RED}✗${NC} %s\n" "$message"
        echo -e "${RED}An error occurred. Please check the log file for details: /tmp/spinner.log${NC}"
        cat /tmp/spinner.log
        exit 1
    fi
}

# --- Main Script Logic ---

# 1. Check if the directory is empty (or contains only this script)
script_name=$(basename "$0")
# List all items in the directory, but exclude the script itself.
# If the result is not empty, then there are other files present.
if [ -n "$(ls -A | grep -v "^${script_name}$")" ]; then
    echo -e "${RED}Error: This script must be run in an empty directory."
    echo -e "Please create a new directory, move only the '${script_name}' script into it, and run it from there.${NC}"
    exit 1
fi

echo -e "${BLUE}--- Starting Project Setup ---${NC}"

# 2. Create project structure and files directly.
# We don't use the spinner here because file creation is instant and avoids
# complex shell parsing issues with 'eval' and multi-line strings.

printf "Creating 'functions' directory... "
mkdir functions
echo -e "${GREEN}✓${NC}"

printf "Creating Julia helper script (functions.jl)... "
cat > functions/functions.jl << 'EOF'
# This script contains the helper functions for the Julia portion of the pipeline.
using LinearAlgebra, Distributions, DataFrames, Arrow, Random

function simulate_rbc_model(α, β, δ, ρ, σ, σ_z)

    y_k = ((1/β) - 1 + δ) / α

    a_quad = y_k - δ
    b_quad = -( (1-β*(1-δ))*(y_k - δ) + y_k*(1+α) + 1 )
    c_quad = y_k * α

    c_ck = (-b_quad - sqrt(b_quad^2 - 4*a_quad*c_quad)) / (2*a_quad)

    c_kk = (y_k * α) / (y_k - δ - c_ck)
    c_cz = (y_k * (1 - c_kk * (1 - α) * β * ρ)) /
           ( (y_k - δ - c_ck) * (1 - β * ρ) + σ * (1 - c_ck) * (1 - β * ρ) )
    c_kz = (c_cz * (1 - c_ck)) / (y_k * (1 - α))

    T = [c_kk  c_kz * ρ
         0     ρ      ]

    R = [c_kz ; 1]

    i_y_ss = δ * (α / ((1/β) - 1 + δ))

    C = [α      1
         c_ck   c_cz
         (c_kk - (1-δ))/i_y_ss   c_kz/i_y_ss]

    Random.seed!(1234)
    n_periods = 250
    shocks = randn(n_periods) * σ_z

    states = zeros(2, n_periods)
    for t in 2:n_periods
        k_t = T[1,1]*states[1, t] + T[1,2]*states[2, t] + R[1]*shocks[t]
        z_tp1 = T[2,1]*states[1, t] + T[2,2]*states[2, t] + R[2]*shocks[t]

        states[1, t] = k_t
        states[2, t] = z_tp1
    end
    k_lag = [0; states[1, 1:end-1]]
    z = [0; states[2, 1:end-1]]

    observables = C * [k_lag'; z']

    df = DataFrame(
        period = 1:n_periods,
        output = observables[1, :],
        consumption = observables[2, :],
        investment = observables[3, :],
        capital = k_lag,
        technology = z
    )

    return df
end

function arrow_write(df::DataFrame, path::String)
    Arrow.write(path, df)
end
EOF
echo -e "${GREEN}✓${NC}"

printf "Creating Python helper script (functions.py)... "
cat > functions/functions.py << 'EOF'
# This script contains modular helper functions for the Python portion of the pipeline.
import pandas as pd
import pyarrow.feather as feather
from sklearn.model_selection import train_test_split
import xgboost as xgb

def prepare_features(simulated_df: pd.DataFrame) -> pd.DataFrame:
    df = simulated_df.copy()
    for col in ['output', 'consumption', 'investment', 'capital', 'technology']:
        df[f'{col}_lag1'] = df[col].shift(1)
    df.dropna(inplace=True)
    return df

def get_X_train(processed_df: pd.DataFrame):
    features = [col for col in processed_df.columns if '_lag1' in col]
    X = processed_df[features]
    train_size = int(0.75 * len(X))
    return X[:train_size]

def get_y_train(processed_df: pd.DataFrame):
    y = processed_df['output']
    train_size = int(0.75 * len(y))
    return y[:train_size]

def get_X_test(processed_df: pd.DataFrame):
    features = [col for col in processed_df.columns if '_lag1' in col]
    X = processed_df[features]
    train_size = int(0.75 * len(X))
    return X[train_size:]

def get_y_test(processed_df: pd.DataFrame):
    y = processed_df['output']
    train_size = int(0.75 * len(y))
    return y[train_size:]

def train_model(X_train: pd.DataFrame, y_train: pd.Series):
    model = xgb.XGBRegressor(
        objective='reg:squarederror',
        n_estimators=100,
        learning_rate=0.1,
        max_depth=3,
        random_state=42
    )
    model.fit(X_train, y_train)
    return model

def make_predictions(model, X_test: pd.DataFrame):
    return model.predict(X_test)

def format_results(y_test: pd.Series, predictions) -> pd.DataFrame:
    results_df = pd.DataFrame({
        'period': y_test.index,
        'actual_output': y_test.values,
        'predicted_output': predictions
    })
    return results_df

def save_arrow(df: pd.DataFrame, path: str):
    feather.write_feather(df, path)
EOF
echo -e "${GREEN}✓${NC}"

printf "Creating R helper script (functions.R)... "
cat > functions/functions.R << 'EOF'
# This script contains the helper functions for the R portion of the pipeline.
# It defines the visualization logic using ggplot2.
library(ggplot2)
library(dplyr)

plot_predictions <- function(predictions_df) {
  p <- ggplot(predictions_df, aes(x = period)) +
    geom_line(
      aes(y = actual_output, color = "Actual (RBC Model)"),
      linewidth = 1
    ) +
    geom_line(
      aes(y = predicted_output, color = "Predicted (XGBoost)"),
      linetype = "dashed",
      linewidth = 1
    ) +
    scale_color_manual(
      name = "Series",
      values = c("Actual (RBC Model)" = "blue", "Predicted (XGBoost)" = "red")
    ) +
    labs(
      title = "XGBoost Prediction of RBC Model Output",
      subtitle = "Forecasting next-quarter output based on current-quarter economic variables",
      x = "Time (Quarters)",
      y = "Output (Log-deviations from steady state)"
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")
  return(p)
}
EOF
echo -e "${GREEN}✓${NC}"

printf "Creating environment definition script (gen-env.R)... "
cat > gen-env.R << 'EOF'
# This script defines the polyglot environment our pipeline will run in.
library(rix)

rix(
  date = "2025-10-14",
  r_pkgs = c(
    "ggplot2", "ggdag", "dplyr", "arrow", "rix", "rixpress", "quarto"
  ),
  jl_conf = list(
    jl_version = "lts",
    jl_pkgs = c("Distributions", "DataFrames", "Arrow", "Random")
  ),
  py_conf = list(
    py_version = "3.13",
    py_pkgs = c("pandas", "scikit-learn", "xgboost", "pyarrow", "ryxpress")
  ),
  ide = "none",
  project_path = ".",
  overwrite = TRUE
)

message("Successfully generated 'default.nix' environment file.")
EOF
echo -e "${GREEN}✓${NC}"

printf "Creating pipeline definition script (gen-pipeline.R)... "
cat > gen-pipeline.R << 'EOF'
# This script defines and orchestrates the entire reproducible analytical pipeline.
library(rixpress)

# Define the full pipeline as a list of derivations.
# This avoids using the '|>' pipe, which can be misinterpreted by the shell.
pipeline_steps <- list(
  # STEP 0: Define RBC Model Parameters
  rxp_jl(alpha, 0.3),
  rxp_jl(beta, 1 / 1.01),
  rxp_jl(delta, 0.025),
  rxp_jl(rho, 0.95),
  rxp_jl(sigma, 1.0),
  rxp_jl(sigma_z, 0.01),

  # STEP 1: Julia - Simulate a Real Business Cycle (RBC) model
  rxp_jl(
    name = simulated_rbc_data,
    expr = "simulate_rbc_model(alpha, beta, delta, rho, sigma, sigma_z)",
    user_functions = "functions/functions.jl",
    encoder = "arrow_write"
  ),

  # STEP 2.1: Python - Prepare features
  rxp_py(
    name = processed_data,
    expr = "prepare_features(simulated_rbc_data)",
    user_functions = "functions/functions.py",
    decoder = "feather.read_feather"
  ),

  # STEP 2.2: Python - Split data
  rxp_py(name = X_train, expr = "get_X_train(processed_data)", user_functions = "functions/functions.py"),
  rxp_py(name = y_train, expr = "get_y_train(processed_data)", user_functions = "functions/functions.py"),
  rxp_py(name = X_test, expr = "get_X_test(processed_data)", user_functions = "functions/functions.py"),
  rxp_py(name = y_test, expr = "get_y_test(processed_data)", user_functions = "functions/functions.py"),

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

  # STEP 2.5: Python - Format final results
  rxp_py(
    name = predictions,
    expr = "format_results(y_test, model_predictions)",
    user_functions = "functions/functions.py",
    encoder = "save_arrow"
  ),

  # STEP 3: R - Visualize the predictions
  rxp_r(
    name = output_plot,
    expr = plot_predictions(predictions),
    user_functions = "functions/functions.R",
    decoder = arrow::read_feather
  ),

  # STEP 4: Quarto - Compile the final report
  rxp_qmd(
    name = final_report,
    qmd_file = "readme.qmd"
  )
)

# Populate and run the pipeline from the list defined above.
rxp_populate(
  pipeline_steps,
  py_imports = c(
    pandas = "import pandas as pd",
    pyarrow = "import pyarrow.feather as feather",
    sklearn = "from sklearn.model_selection import train_test_split",
    xgboost = "import xgboost as xgb"
  ),
  project_path = ".",
  build = TRUE,
  verbose = 1
)

rxp_copy("final_report")
EOF
echo -e "${GREEN}✓${NC}"

printf "Creating Quarto report template (readme.qmd)... "
cat > readme.qmd << 'EOF'
---
title: "RBC Model Analysis Report"
format: 
  html:
    embed-resources: true
    toc: true
---

## Model Performance

The plot below compares the actual output from the RBC model simulation against the predictions generated by the XGBoost model.

```{r}
#| echo: false
#| label: rbc-plot
#| fig-cap: "Comparison of Actual RBC Model Output vs. XGBoost Predictions"

# The {rixpress} pipeline generates the plot object and makes it available
# to this Quarto document. We load the final plot from the results.
rixpress::rxp_read("output_plot")
```
EOF
echo -e "${GREEN}✓${NC}"


echo -e "\n${BLUE}--- Executing Reproducible Pipeline ---${NC}"
echo -e "${YELLOW}This may take a significant amount of time, especially on the first run, as Nix will download and build all software from scratch.${NC}"

# 3. Build the Nix environment from gen-env.R
CMD1="nix-shell --expr \"\$(curl -sl https://raw.githubusercontent.com/ropensci/rix/main/inst/extdata/default.nix)\" --run \"Rscript gen-env.R\""
run_with_spinner "$CMD1" "Building the Nix environment (this is the longest step)"

# 4. Run the pipeline using the now-created environment
CMD2="nix-shell --run \"Rscript gen-pipeline.R\""
run_with_spinner "$CMD2" "Running the polyglot analysis pipeline"

echo -e "\n${GREEN}--- Pipeline execution complete! ---${NC}"
echo "All artifacts, including the final report and plot, have been generated."
echo "You can view the final HTML report by opening: ${BLUE}final_report/readme.html${NC}"
