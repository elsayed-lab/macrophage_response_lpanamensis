#!/usr/bin/env bash
start=$(pwd)
source /usr/local/etc/bashrc
log=/setup_local.stdout
err=/setup_local.stderr
## Adding a few random packages used for rendering the ML classifier document.
echo "Installing a few ML packages." | tee -a ${log}
Rscript -e 'BiocManager::install(c("glmnet", "ranger", "xgboost"))' 2>${err} 1>>${log}
## Adding a few random packages used for rendering the WGCNA document.
Rscript -e 'BiocManager::install(c("irr", "CorLevelPlot", "flashClust"))' 2>>${err} 1>>${log}
Rscript -e 'BiocManager::install(c("AnnotationHub", "AnnotationHubData"))'
Rscript -e 'BiocManager::install("Heatplus")'
## I have no idea why upsetr did not get installed, it is in the description
Rscript -e 'BiocManager::install("UpSetR")'

echo "Cloning the git repository of eupathdb." | tee -a ${log}
git clone https://github.com/abelew/EuPathDB.git 2>>${err} 1>>${log}
cd EuPathDB || exit
make deps
make install

cd $start

Rscript -e 'library(EuPathDB); meta <- download_eupath_metadata(webservice = "tritrypdb"); panamensis_entry <- get_eupath_entry("MHOM", metadata = meta[["valid"]]); panamensis_db <- make_eupath_orgdb(panamensis_entry)'
