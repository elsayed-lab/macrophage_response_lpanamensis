#!/usr/bin/env bash
start=$(pwd)
##commit="b26529d25251c3d915b718460ef34194dbf8e418"
log=/setup_hpgltools.stdout
err=/setup_hpgltools.stderr
prefix="/sw/local/conda/${VERSION}"
## I know one shouldn't use cat | grep, but I don't trust the proc filesystem to act like a file.
cpus=$(cat /proc/cpuinfo | grep -c processor)
echo "Starting setup_hpgltools, downloading required headers and utilities." | tee -a ${log}

## The following installation is for stuff needed by hpgltools, these may want to be moved
## to the following mamba stanza
apt-get -y install libharfbuzz-dev libfribidi-dev libjpeg-dev libxft-dev libfreetype6-dev \
        libmpfr-dev libnetcdf-dev libtiff-dev wget 1>/dev/null 2>${err}
apt-get clean

echo "Installing mamba with hpgltools env to ${prefix}." | tee -a ${log}
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -axvj bin/micromamba | tee -a ${log}
echo "Creating hpgltools conda environment." | tee -a ${log}
micromamba --root-prefix="${prefix}" --yes create -n hpgltools \
           glpk imagemagick mpfr netcdf4 pandoc r-base=4.3.3 \
           -c conda-forge 1>>${log} 2>>${err}
echo "Activating hpgltools" | tee -a ${log}
source /usr/local/etc/bashrc
## Beginning hpgltools installation. The next line might be dangerous
## if singularity maps ~root and writes to the underlying filesystem.
## Ok, so I tested with and without setting Ncpus in ~/.Rprofile.
## I am now reasonably certain that /root is not being bound, so that is good.
echo "options(Ncpus=${cpus})" > "${HOME}/.Rprofile"
echo "options(timeout=600)" >> "${HOME}/.Rprofile"
echo "options(repos='https://cloud.r-project.org')" >> "${HOME}/.Rprofile"
#echo "options(Bioc_mirror='')" >> ${HOME}/.Rprofile
##echo "options(repos='https://bioconductor.org/packages/${BIOC_VERSION}/bioc')" >> ${HOME}/.Rprofile
echo "Cloning the hpgltools repository." | tee -a ${log}
git clone https://github.com/abelew/hpgltools.git 1>>${log} 2>>${err}
cd hpgltools || exit

#echo "Explicitly setting to the commit which was last used for the analyses."
#git reset ${commit} --hard

## It turns out I cannot allow R to install the newest bioconductor version arbitrarily because
## not every package gets checked immediately, this caused everything to explode!
echo "Installing bioconductor version ${BIOC_VERSION}."
Rscript -e "install.packages('BiocManager', repo='http://cran.rstudio.com/')"
Rscript -e "BiocManager::install(version='${BIOC_VERSION}', ask=FALSE)"

echo "Installing non-base R prerequisites, essentially tidyverse." | tee -a ${log}
Rscript -e "BiocManager::install(c('devtools', 'tidyverse'), force=TRUE, update=TRUE, ask=FALSE)"

echo "Installing hpgltools dependencies with bioconductor." | tee -a ${log}
Rscript -e 'devtools::install_dev_deps(".", dependencies = "Depends")'
Rscript -e 'devtools::install_dev_deps(".", dependencies = "Imports")'
Rscript -e 'devtools::install_dev_deps(".", dependencies = "Suggests")'

## preprocessCore has a bug which is triggered from within containers...
## https://github.com/Bioconductor/bioconductor_docker/issues/22
echo "Installing preprocessCore without threading to get around a container-specific bug." | tee -a ${log}
Rscript -e "BiocManager::install('preprocessCore', configure.args=c(preprocessCore='--disable-threading'), ask=FALSE, force=TRUE, update=TRUE, type='source')"


## It appears the ggtree package is having troubles...
echo "Installing a dev version of ggtree due to weirdo errors, this is super annoying." | tee -a ${log}
Rscript -e 'remotes::install_github("YuLab-SMU/ggtree")'
echo "In my last revision I got weird clusterProfiler loading errors, testing it out here." | tee -a ${log}
Rscript -e 'BiocManager::install(c("DOSE", "clusterProfiler"), force=TRUE, update=TRUE, ask=FALSE)'

## I like these sankey plots and vennerable, but they are not in bioconductor.
echo "Installing ggsankey and vennerable." | tee -a ${log}
Rscript -e 'devtools::install_github("davidsjoberg/ggsankey")' 1>/dev/null 2>>${err}
Rscript -e 'devtools::install_github("js229/Vennerable")' 1>/dev/null 2>>${err}
## The new version of dbplyr is broken and causes my annotation download to fail, and therefore _everything_ else.
Rscript -e 'devtools::install_version("dbplyr", version="2.3.4", repos="http://cran.us.r-project.org")' 1>/dev/null 2>>${err}

Rscript -e 'BiocManager::install(), force=TRUE, update=TRUE, ask=FALSE)'

echo "Installing hpgltools itself." | tee -a ${log}
R CMD INSTALL .
cd $start || exit
