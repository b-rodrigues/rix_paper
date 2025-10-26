FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV R_VERSION=4.5.1
ENV PYTHON_VERSION=3.13.8
ENV JULIA_VERSION=1.10.5
ENV QUARTO_VERSION=1.8.25

# Install required packages, INCLUDING 'make' for the pipeline
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  ca-certificates \
  make

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

# Configure R to use the Posit Package Manager snapshot.
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/2025-10-14"))' > /root/.Rprofile

# Install R packages.
RUN R -e "install.packages(c('ggplot2', 'ggdag', 'dplyr', 'arrow', 'rix', 'rixpress', 'quarto'))"

####################################
# Quarto
####################################
RUN curl -L "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb" -o /tmp/quarto.deb && \
    apt-get install -y /tmp/quarto.deb && \
    rm /tmp/quarto.deb

####################################
# Julia
####################################

# Download and extract Julia
RUN curl -fsSL https://julialang-s3.julialang.org/bin/linux/x64/$(echo ${JULIA_VERSION} | cut -d. -f1-2)/julia-${JULIA_VERSION}-linux-x86_64.tar.gz \
    | tar -xzC /opt
RUN ln -s /opt/julia-${JULIA_VERSION}/bin/julia /usr/local/bin/julia

# Install specific versions of Julia packages for reproducibility
RUN julia -e 'using Pkg; \
    Pkg.add(name="Arrow", version="2.8.0"); \
    Pkg.add(name="DataFrames", version="1.8.0"); \
    Pkg.add(name="Distributions", version="0.25.122")'


####################################
# Pipeline Execution
####################################

WORKDIR /rbc

# Copy the entire rbc project directory into the newly set WORKDIR (/rbc).
# '.' now refers to /rbc.
COPY ./rbc .

# Run the Makefile to execute the entire pipeline from within /rbc.
# This builds all artifacts (data files, plot) and caches them in the image layer.
RUN make all

####################################
# Final Configuration
####################################

# The default command is a shell. Since the pipeline has already run,
# you can use this to explore the results inside /rbc (e.g., ls -R data plots).
CMD ["/bin/bash"]