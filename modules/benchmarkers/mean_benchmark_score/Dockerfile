FROM r-base
LABEL authors="Jose Espinosa-Carrasco" \
      description="Docker image containing R packages for the mean benchmark score"

RUN apt-get update && apt-get install -y procps && apt-get clean -y

# Install the conda environment
# COPY environment.yml /
# RUN conda env create -f /environment.yml && conda clean -a
