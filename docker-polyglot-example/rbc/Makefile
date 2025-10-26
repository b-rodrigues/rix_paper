# ==============================================================================
# Makefile for the Polyglot RBC Model Pipeline
# ==============================================================================

# Define the interpreters for each language.
JULIA := julia
PYTHON := python
RSCRIPT := Rscript
QUARTO := quarto

# Define directory variables for better organization.
DATA_DIR := data
PLOTS_DIR := plots
REPORT_DIR := report
FUNCTIONS_DIR := functions

# Define the final and intermediate data files.
SIMULATED_DATA := $(DATA_DIR)/simulated_rbc_data.arrow
PREDICTIONS := $(DATA_DIR)/predictions.arrow
FINAL_PLOT := $(PLOTS_DIR)/output_plot.png
FINAL_REPORT := $(REPORT_DIR)/readme.html

# --- Main Rules ---

# The default 'all' rule now points to the final compiled HTML report.
all: $(FINAL_REPORT)

# Rule to render the final Quarto report.
# Depends on the Quarto source file and the plot from the R step.
$(FINAL_REPORT): readme.qmd $(FINAL_PLOT) | $(REPORT_DIR)
	@echo "--- [Quarto] Compiling final report ---"
	$(QUARTO) render $< --to html --output-dir $(REPORT_DIR)

# Rule to generate the final plot.
# Depends on the R script and the prediction data from the Python step.
$(FINAL_PLOT): 03_visualize_results.R $(PREDICTIONS) | $(PLOTS_DIR)
	@echo "--- [R] Visualizing model predictions ---"
	$(RSCRIPT) $< $(PREDICTIONS) $@

# Rule to generate the prediction data.
# Depends on the Python script and the simulated data from the Julia step.
$(PREDICTIONS): 02_train_model.py $(SIMULATED_DATA)
	@echo "--- [Python] Training model and making predictions ---"
	$(PYTHON) $< $(SIMULATED_DATA) $@

# Rule to generate the simulated RBC data.
# Depends on the Julia script and its helper functions.
$(SIMULATED_DATA): 01_simulate_rbc.jl $(FUNCTIONS_DIR)/functions.jl | $(DATA_DIR)
	@echo "--- [Julia] Simulating RBC model data ---"
	$(JULIA) $< $@

# --- Utility Rules ---

# This rule creates all output directories if they don't exist.
$(DATA_DIR) $(PLOTS_DIR) $(REPORT_DIR):
	@echo "Creating directory: $@"
	mkdir -p $@

# The 'clean' rule removes all generated files and directories.
clean:
	@echo "Cleaning up generated files..."
	rm -rf $(DATA_DIR) $(PLOTS_DIR) $(REPORT_DIR)

# Phony targets are not files. They are just names for commands.
.PHONY: all clean
