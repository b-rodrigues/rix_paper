### Handling software outside of nixpkgs

A common challenge in reproducible research is managing software that is not available in the central package repository (in this case, `nixpkgs`). This includes packages only available on development platforms like GitHub, or custom analysis code written specifically for the project (such as a C++ program).

#### Installing development versions of packages

For [R]{.proglang} packages that are not on CRAN or packaged in `nixpkgs`, [rix]{.pkg} provides the `git_pkgs` parameter. Users can specify the package name, the repository URL, and a specific git commit hash:

::: {.content-hidden when-format="pdf"}
```r
rix(date = "2025-10-20",
  r_pkgs = c("dplyr"),
  git_pkgs = list(
    package_name = "fusen",
    repo_url = "https://github.com/ThinkR-open/fusen",
    commit = "60346860111be79fc2beb33c53e195f97504a667"
  ),
  project_path = ".",
  overwrite = TRUE)
```
:::
```latex
\begin{CodeInput}
R> rix(date = "2025-10-20",
+    r_pkgs = c("dplyr"),
+    git_pkgs = list(
+      package_name = "fusen",
+      repo_url = "https://github.com/ThinkR-open/fusen",
+      commit = "60346860111be79fc2beb33c53e195f97504a667"
+    ),
+    project_path = ".",
+    overwrite = TRUE)
\end{CodeInput}
```

Under the hood, [rix]{.pkg} generates Nix expressions that fetch the specific commit from GitHub and build the package from source within the isolated, sandboxed Nix build environment. This ensures that even development versions of packages remain completely reproducible over time, without depending on external hosting state or changing refs.

#### Custom compiled analysis software

For custom-written programs (e.g., a compiled C++ tool specific to the analysis), users have two main choices:

1. **Interactive compilation**: By adding compiler toolchains (such as `gcc`, `clang`, `gmake`, or `cmake`) to the `system_pkgs` argument of `rix()`, the Nix shell provides a complete, hermetic environment for compiling the custom software locally. The user or a workflow script can run `make` or compilation commands (e.g., `g++ -O3 -o my_analysis analysis.cpp`) inside the shell, guaranteeing that the exact same compiler version and system libraries are used.
2. **Declarative packaging**: For a fully declarative approach, users can write a custom Nix derivation (using `stdenv.mkDerivation`) that defines the build instructions for the custom software. This custom derivation can then be imported into the `default.nix` file, allowing Nix to build and manage the custom software in the same content-addressed, sandboxed manner as packages from `nixpkgs`.
