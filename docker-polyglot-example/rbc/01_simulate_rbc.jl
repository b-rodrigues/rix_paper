# ==============================================================================
# 01_simulate_rbc.jl
#
# Simulates data from a Real Business Cycle (RBC) model and saves it.
#
# Usage: julia 01_simulate_rbc.jl <output_path>
# Example: julia 01_simulate_rbc.jl data/simulated_rbc_data.arrow
# ==============================================================================

# Load required packages
using Distributions, DataFrames, Arrow, Random

# Include the helper functions from the separate file.
include("functions/functions.jl")

# Check if the output path is provided as a command-line argument.
if length(ARGS) != 1
    error("Usage: julia 01_simulate_rbc.jl <output_path>")
end

# Get the output path from the first command-line argument.
output_path = ARGS[1]

# --- Define RBC Model Parameters ---
# These were previously defined as individual steps in the rixpress script.
α = 0.3         # Capital's share of income
β = 1 / 1.01    # Discount factor
δ = 0.025       # Depreciation rate
ρ = 0.95        # Technology shock persistence
σ = 1.0         # Risk aversion (log-utility)
σ_z = 0.01      # Technology shock standard deviation

# --- Run the Simulation ---
println("Simulating RBC model...")
simulated_df = simulate_rbc_model(α, β, δ, ρ, σ, σ_z)

# --- Save the Output ---
println("Saving simulated data to: ", output_path)
arrow_write(simulated_df, output_path)

println("Julia script finished successfully.")