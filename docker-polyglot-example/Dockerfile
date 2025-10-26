FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV R_VERSION=4.5.1
ENV PYTHON_VERSION=3.13.8
ENV JULIA_VERSION=1.10.5

# Install required packages to download script
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  ca-certificates

####################################
# Python
####################################
# Download the latest uv installer
ADD https://astral.sh/uv/0.9.5/install.sh /uv-installer.sh

# Run the installer then remove it
RUN sh /uv-installer.sh && rm /uv-installer.sh

# Ensure the installed binary is on the `PATH`
ENV PATH="/root/.local/bin/:$PATH"

# Install the specified Python version using uv.
RUN uv python install ${PYTHON_VERSION}

# Setup default virtual env
# Each Python command will run here by default
RUN uv venv /opt/venv
# Use the virtual environment automatically
ENV VIRTUAL_ENV=/opt/venv
# Place entry points in the environment at the front of the path
ENV PATH="/opt/venv/bin:$PATH"

# Install Python packages using uv with specific versions for reproducibility.
RUN echo "pandas==2.3.3" > /tmp/requirements.txt && \
    echo "scikit-learn==1.7.2" >> /tmp/requirements.txt && \
    echo "xgboost==3.1.1" >> /tmp/requirements.txt && \
    echo "pyarrow==21.0.0" >> /tmp/requirements.txt && \
    echo "ryxpress==0.0.9" >> /tmp/requirements.txt

RUN uv pip install --no-cache -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

####################################
# R
####################################

# Setup rig to manage R
RUN curl -L https://rig.r-pkg.org/deb/rig.gpg -o /etc/apt/trusted.gpg.d/rig.gpg

RUN sh -c 'echo "deb http://rig.r-pkg.org/deb rig main" > /etc/apt/sources.list.d/rig.list'

RUN apt-get update && apt-get install -y --no-install-recommends r-rig

# Install the specified R version with rig and set it as the default.
RUN rig add ${R_VERSION} && rig default ${R_VERSION}

# Configure R to use the Posit Package Manager snapshot for reproducibility.
# Also install binaries of packages for fast installation
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/2025-10-14"))' > /root/.Rprofile

# Install R packages.
RUN R -e "install.packages(c('ggplot2', 'ggdag', 'dplyr', 'arrow', 'rix', 'rixpress', 'quarto'))"

####################################
# Julia
####################################

RUN curl -fsSL https://julialang-s3.julialang.org/bin/linux/x64/$(echo ${JULIA_VERSION} | cut -d. -f1-2)/julia-${JULIA_VERSION}-linux-x86_64.tar.gz \
    | tar -xzC /opt
# Create symlink to Julia binary
RUN ln -s /opt/julia-${JULIA_VERSION}/bin/julia /usr/local/bin/julia

# Create a proper Project.toml with version constraints
RUN mkdir -p /opt/julia-project && \
    echo '[deps]' > /opt/julia-project/Project.toml && \
    echo 'Arrow = "69666777-d1a9-59fb-9406-91d4454c9d45"' >> /opt/julia-project/Project.toml && \
    echo 'DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"' >> /opt/julia-project/Project.toml && \
    echo 'Distributions = "31c24e10-a181-5473-b8eb-cc856c621d33"' >> /opt/julia-project/Project.toml && \
    echo '' >> /opt/julia-project/Project.toml && \
    echo '[compat]' >> /opt/julia-project/Project.toml && \
    echo 'Arrow = "2.8.0"' >> /opt/julia-project/Project.toml && \
    echo 'DataFrames = "1.8.0"' >> /opt/julia-project/Project.toml && \
    echo 'Distributions = "0.25.122"' >> /opt/julia-project/Project.toml

RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'

# Set the default command to a shell for interactive use.
CMD ["/bin/bash"]