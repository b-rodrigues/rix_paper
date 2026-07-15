### Conda and Spack

Beyond containerization, other tools address system-level dependencies.
[conda]{.pkg} [@anaconda] is a cross-platform package and environment manager
that has been widely adopted since its release in 2012, particularly in the
[Python]{.proglang} and data science communities. [Spack]{.pkg}
[@gamblin2015spack] is a related but distinct tool aimed primarily at HPC
environments, where fine-grained control over compiler flags and
architecture-specific optimizations is essential. While both handle
system-level dependencies and support polyglot runtimes, [Nix]{.pkg} differs
from them in several important ways.

First, [Nix]{.pkg} builds every package in a strictly sandboxed environment
where network access is disabled and host environment variables are purged,
preventing host-system libraries from leaking into the build. [conda]{.pkg}
recipes are built without sandbox isolation, meaning compilation can silently
depend on libraries present on the host system. Second, packages in [Nix]{.pkg}
are installed into read-only paths under `/nix/store/` whose names are hashes
of all build inputs—source code, compiler version, build flags, and
dependencies. [conda]{.pkg} environments are mutable directories where packages
can be updated or removed in-place, which can lead to environment drift and
silent mutation. Finally, because [conda]{.pkg} relies on mutable repositories
and does not strictly isolate the bootstrap paths of compilers and core
libraries, legacy [conda]{.pkg} environments frequently fail to rebuild years
later due to channel updates or changes in the host's system libraries.
[Nix]{.pkg} pins the entire repository to a specific [Git]{.pkg} commit, guaranteeing
that the complete build tree—including compilers—is reconstructed exactly as it
was. As discussed in Section @sec-nix and empirically validated by @malka2025,
this functional model achieves high rebuildability and bit-for-bit
reproducibility rates even across multi-year timeframes.

### Comparison with modern workflow engines

While GNU [Make]{.pkg} remains a classic tool for scientific workflows, modern
pipelines are often orchestrated using dedicated engines like [Snakemake]{.pkg}
[@moelder2021snakemake] and [Nextflow]{.pkg} [@di2017nextflow]. These engines
support polyglot steps and per-step environments via [conda]{.pkg} or
containerization, and have mature ecosystems for HPC schedulers (SLURM, SGE,
LSF) and cloud environments. [rixpress]{.pkg} offers a different set of
trade-offs.

On the one hand, [rixpress]{.pkg} provides a more unified experience: both the
computational environments and the workflow steps are defined programmatically
through a single [R]{.proglang} interface, whereas combining [Snakemake]{.pkg}
or [Nextflow]{.pkg} with [conda]{.pkg} or [Docker]{.pkg} requires writing
pipeline steps in a separate DSL and maintaining distinct dependency files such
as Conda YAMLs or Dockerfiles. [rixpress]{.pkg} also handles data serialization
automatically, passing objects between [R]{.proglang}, [Python]{.proglang}, and
[Julia]{.proglang} steps without the user needing to manually write and read
intermediate files.

On the other hand, [rixpress]{.pkg} has real limitations that users should be
aware of. Its language support is currently limited to [R]{.proglang},
[Python]{.proglang}, and [Julia]{.proglang}: executing arbitrary command-line
tools requires wrapping them in [R]{.proglang} or [Python]{.proglang} code, or
defining a dedicated shell step, whereas [Snakemake]{.pkg} and [Nextflow]{.pkg}
treat shell commands as first-class steps. Because [rixpress]{.pkg} executes
pipeline steps as [Nix]{.pkg} derivations, intermediate inputs and outputs are
stored in `/nix/store/`, which introduces storage and performance overhead for
workflows with large intermediate artifacts—a consideration particularly
relevant in domains such as genomics or imaging. Finally, [Snakemake]{.pkg} and
[Nextflow]{.pkg} have native executors for HPC schedulers and cloud
environments, whereas [rixpress]{.pkg} currently only supports local
parallelization.

