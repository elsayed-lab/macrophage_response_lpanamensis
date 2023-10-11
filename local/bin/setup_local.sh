#!/usr/bin/env bash
start=$(pwd)
source /usr/local/etc/bashrc
## Adding a few random packages used for rendering the ML classifier document.
Rscript -e 'BiocManager::install(c("glmnet", "ranger", "xgboost"))'
## Adding a few random packages used for rendering the WGCNA document.
Rscript -e 'BiocManager::install(c("irr", "CorLevelPlot", "flashClust"))'

git clone https://github.com/abelew/EuPathDB.git
cd EuPathDB || exit
make install

cd $start

Rscript -e 'library(EuPathDB); meta <- download_eupath_metadata(webservice = "tritrypdb"); panamensis_entry <- get_eupath_entry("MHOM", metadata = meta[["valid"]]); panamensis_db <- make_eupath_orgdb(panamensis_entry)'
