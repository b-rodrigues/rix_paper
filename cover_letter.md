# Cover Letter

**Date:** January 6, 2026

**To:** The Editors, Journal of Statistical Software

**Subject:** Manuscript Submission – "Nix for Polyglot, Reproducible Data Science Workflows"

---

Dear Editors,

We are pleased to submit our manuscript titled **"Nix for Polyglot, Reproducible Data Science Workflows"** for consideration in the Journal of Statistical Software.

## Summary

This paper introduces two R packages, **rix** and **rixpress** (and it's Python equivalent **ryxpress**) that make the Nix package manager accessible to researchers without requiring expertise in functional programming or systems administration. Together, these packages address two fundamental challenges in reproducible research:

1. **Environment Management**: rix generates Nix expressions from intuitive R function calls, enabling researchers to define complete computational environments (including R, Python, Julia, system libraries, and LaTeX distributions) that are reproducible across machines and over time.

2. **Workflow Orchestration**: rixpress extends this to entire analysis pipelines, where each step runs in a hermetically sealed environment with automatic caching and dependency tracking—enabling true polyglot workflows without manual orchestration.

## Relevance to JSS

We believe this manuscript is well-suited for JSS because:

- **Software Focus**: The paper presents production-ready software (both packages are on CRAN and have undergone rOpenSci peer review) with comprehensive documentation and vignettes.

- **Reproducibility**: The manuscript itself is fully reproducible using the tools it describes, demonstrating practical applicability. The discussed case-study is fully reproducible by running a single script (provided with the submission).

- **Methodological Contribution**: We provide a systematic comparison of imperative (Docker/Make) versus declarative (Nix) approaches to reproducibility, supported by empirical evidence from large-scale package rebuilding studies.

- **Broad Applicability**: While implemented in R, the framework supports polyglot workflows spanning R, Python, and Julia—addressing the increasingly multi-language nature of modern data science.

## Technical Details

- The **rix** package is available on CRAN and GitHub: https://github.com/ropensci/rix
- The **rixpress** package is available on CRAN and GitHub: https://github.com/ropensci/rixpress
- The **ryxpress** package (Python port) is available on PyPI and GitHub: https://github.com/b-rodrigues/ryxpress
- All source code and replication materials are available at: https://github.com/b-rodrigues/rix_paper

## Author Contributions

All authors contributed to the conceptualization, software development, and manuscript preparation. The corresponding author confirms that all authors have approved the submitted version.

## Declarations

- This manuscript has not been published elsewhere and is not under consideration by another journal
- All authors have approved the manuscript and agree with its submission
- The software is released under the GPL-3 license

We thank you for considering our submission and look forward to your response.

Sincerely,

Bruno Rodrigues (Corresponding Author)  
Department of Statistics  
Ministry of Research and Higher Education  
Luxembourg  
Email: bruno@brodrigues.co

Philipp Baumann  
Data and Analytics  
Alliance SwissPass  
Switzerland  
Email: baumann-philipp@protonmail.com
