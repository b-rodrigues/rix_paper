[![DOI](https://zenodo.org/badge/717253846.svg)](https://doi.org/10.5281/zenodo.18138617)


# Nix for Polyglot, Reproducible Data Science Workflows

This repository contains the source code and reproducible environment for the
paper, "Nix for Polyglot, Reproducible Data Science Workflows".

## Reproducing the Paper

The primary goal of this repository is to demonstrate the reproducibility of the
paper itself. The entire computational environment required to compile the
manuscript from its source is defined using Nix.

### Prerequisites

You must have **Nix** installed on your system (Linux, WSL for Windows or
macOS). We strongly recommend using the [Determinate Systems Nix
Installer](https://determinate.systems/posts/determinate-nix-installer) for a
seamless setup.

### Instructions

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/b-rodrigues/rix_paper.git
    cd rix_paper
    ```

2.  **Render the PDF:**
    ```bash
    nix-shell --run "quarto render paper.qmd --to jss-pdf"
    ```

This single command performs the following actions:
- It reads the `default.nix` file in the repository.
- It builds the exact, bit-for-bit identical environment containing Quarto, a
   TeXLive distribution, and all necessary fonts and dependencies.
- It then executes the `quarto render` command inside that environment.

The first time you run this command, Nix will download and build all
dependencies, which may take a considerable amount of time. Subsequent runs will
be nearly instantaneous due to caching.

Upon completion, you will find the compiled manuscript at `paper.pdf`.

## Running the Polyglot Example

The paper discusses a complete polyglot example that simulates an economic model
in Julia, trains a machine learning model in Python, and visualizes the results
in R. This repository includes a script to set up and run this entire pipeline
from scratch.

### Instructions

1.  **Navigate to the example directory:**
    ```bash
    cd polyglot-example 
    ```

2.  **Make the script executable:**
    ```bash
    chmod +x run_polyglot_example.sh
    ```

3.  **Run the script:**
    ```bash
    ./run_polyglot_example.sh
    ```

This script will:

1.  Generate all the necessary project files (`functions.jl`, `functions.py`, etc.).
2.  Build the complete polyglot Nix environment defined in `gen-env.R`.
3.  Execute the entire analysis pipeline defined in `gen-pipeline.R`.

The final output will be an HTML report located at
`polyglot-example/pipeline-output/readme.html`.

## Repository Structure

-   `paper.qmd`: The Quarto source file for the manuscript.
-   `bibliography.bib`: The BibTeX file containing all citations.
-   `default.nix`: The Nix expression that defines the environment for compiling the paper.
-   `polyglot-example/`: A directory containing the self-contained script to run the paper's main example.
-   `.github/workflows/`: Contains the GitHub Actions configuration, which automatically re-compiles the paper on every push to validate its reproducibility.

## License

The code in this repository is licensed under the [GPL v3](LICENSE.md).
