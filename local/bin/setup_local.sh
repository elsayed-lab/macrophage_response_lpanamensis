#!/usr/bin/env bash
start=$(pwd)
source /usr/local/etc/bashrc
log=/setup_local.stdout
err=/setup_local.stderr
## Adding a few random packages used for rendering the ML classifier document.
echo "Installing a few ML packages." | tee -a ${log}
Rscript -e 'BiocManager::install(c("glmnet", "ranger", "xgboost"))' 2>/dev/null 1>&2
## Adding a few random packages used for rendering the WGCNA document.
echo "Installing some annotation and plotters." | tee -a ${log}
Rscript -e 'BiocManager::install(c("irr", "CorLevelPlot", "flashClust"))' 2>/dev/null 1>&2
Rscript -e 'BiocManager::install(c("AnnotationHub", "AnnotationHubData"))' 2>/dev/null 1>&2
Rscript -e 'BiocManager::install("Heatplus")' 2>/dev/null 1>&2
## I have no idea why upsetr did not get installed, it is in the description
Rscript -e 'BiocManager::install("UpSetR")' 2>/dev/null 1>&2

echo "Cloning the git repository of eupathdb." | tee -a ${log}
git clone https://github.com/abelew/EuPathDB.git 2>/dev/null 1>&2
cd EuPathDB || exit

echo "Installing hpgltools packages from Depends via devtools." | tee -a ${log}
Rscript -e 'devtools::install_dev_deps(".", dependencies = "Depends")' 2>/dev/null 1>&2
echo "Installing hpgltools packages from Imports via devtools." | tee -a ${log}
Rscript -e 'devtools::install_dev_deps(".", dependencies = "Imports")' 2>/dev/null 1>&2
echo "Installing hpgltools packages from Suggests via devtools." | tee -a ${log}
Rscript -e 'devtools::install_dev_deps(".", dependencies = "Suggests")' 2>/dev/null 1>&2

make install 2>/dev/null 1>&2

cd "${start}" || exit

echo "Installing a Leishmania panamensis annotation package." | tee -a ${log}
Rscript -e 'library(EuPathDB); meta <- download_eupath_metadata(webservice = "tritrypdb"); panamensis_entry <- get_eupath_entry("MHOM", metadata = meta[["valid"]]); panamensis_db <- make_eupath_orgdb(panamensis_entry)' 2>/dev/null 1>&2
