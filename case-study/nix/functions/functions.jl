# This script contains the helper functions for the Julia portion of the pipeline.
# It implements the correct, stable, and canonical log-linearized solution to
# a standard Real Business Cycle (RBC) model, based on the provided lecture slides.

#using LinearAlgebra, Distributions, DataFrames, Arrow, Random

#-------------------------------------------------------------------------------
# 1. Main Simulation Function
#-------------------------------------------------------------------------------

"""
    simulate_rbc_model(α, β, δ, ρ, σ, σ_z)

    Takes RBC model parameters as input, solves for the state-space representation
    using the method of undetermined coefficients (as per the slides), simulates
    the model for 250 quarters, and returns a DataFrame.
"""
function simulate_rbc_model(α, β, δ, ρ, σ, σ_z)

    # --- STEADY-STATE VALUES AND CONSTRUCTED PARAMETERS (Slides p. 16, 31) ---
    y_k = ((1/β) - 1 + δ) / α

    # --- SOLVE FOR POLICY FUNCTION COEFFICIENTS (Slides p. 19-22) ---
    # We solve for the coefficients of the policy functions:
    # c_hat_t = c_ck * k_hat_{t-1} + c_cz * z_hat_t
    # k_hat_t = c_kk * k_hat_{t-1} + c_kz * z_hat_t

    # Solve the quadratic equation for c_ck (coefficient of capital on consumption)
    # Based on Campbell (1994) and slide 22, we take the stable root.
    # a*x^2 + b*x + c = 0
    a_quad = y_k - δ
    b_quad = -( (1-β*(1-δ))*(y_k - δ) + y_k*(1+α) + 1 )
    c_quad = y_k * α

    # The stable solution is the smaller positive root
    c_ck = (-b_quad - sqrt(b_quad^2 - 4*a_quad*c_quad)) / (2*a_quad)

    # Now solve for the other coefficients based on c_ck
    c_kk = (y_k * α) / (y_k - δ - c_ck)
    c_cz = (y_k * (1 - c_kk * (1 - α) * β * ρ)) /
           ( (y_k - δ - c_ck) * (1 - β * ρ) + σ * (1 - c_ck) * (1 - β * ρ) )
    c_kz = (c_cz * (1 - c_ck)) / (y_k * (1 - α))

    # --- BUILD STATE-SPACE MATRICES FROM SOLVED COEFFICIENTS ---
    # State vector: s_t = [k_{t-1}, z_t]'
    # Transition:   s_t = T*s_{t-1} + R*ε_t

    T = [c_kk  c_kz * ρ
         0     ρ      ]

    R = [c_kz ; 1]

    # Observation Matrix for [output, consumption, investment]
    # y_hat_t = α*k_{t-1} + z_t
    # c_hat_t = c_ck*k_{t-1} + c_cz*z_t
    # i_hat_t = (i_y_ss)^-1 * (k_t - (1-δ)k_{t-1})
    #         = (i_y_ss)^-1 * ( (c_kk - (1-δ))k_{t-1} + c_kz*z_t )

    i_y_ss = δ * (α / ((1/β) - 1 + δ))

    C = [α      1
         c_ck   c_cz
         (c_kk - (1-δ))/i_y_ss   c_kz/i_y_ss]

    # --- SIMULATE THE MODEL ---
    Random.seed!(1234)
    n_periods = 250
    shocks = randn(n_periods) * σ_z

    states = zeros(2, n_periods)
    for t in 2:n_periods
        # The state is [k_{t-1}, z_t]'
        # To get the next state [k_t, z_{t+1}]', we first find k_t
        k_t = T[1,1]*states[1, t] + T[1,2]*states[2, t] + R[1]*shocks[t]
        z_tp1 = T[2,1]*states[1, t] + T[2,2]*states[2, t] + R[2]*shocks[t]

        states[1, t] = k_t # This is now k_t, which is "k_lag" for t+1
        states[2, t] = z_tp1 # This is now z_{t+1}
    end
    # Re-aligning states to be [k_{t-1}, z_t]
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

#-------------------------------------------------------------------------------
# 2. Encoder Function (Unchanged)
#-------------------------------------------------------------------------------
"""
    arrow_write(df::DataFrame, path::String)
    Encoder function to save a Julia DataFrame to an Arrow file.
"""
function arrow_write(df::DataFrame, path::String)
    Arrow.write(path, df)
end
