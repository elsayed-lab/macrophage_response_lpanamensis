#!/usr/bin/env bash
set -o errtrace
set -o pipefail
start=$(pwd)
## Note that VERSION here is not the same as the version used to build the container.
export RENDER_VERSION=$(date +%Y%m)


function usage() {
    echo "This script by default will render every file in the list:"
    echo "${inputs}"
    echo "into the directory:"
    echo "${output_dir}"
    echo ""
    echo "It also understands the options: "
    echo "-i: colon-separated list of input files."
    echo "-o: Output directory to write data/outputs."
    echo "-c: Clean up the output directory."
}

function cleanup() {
    echo "Cleaning the output directory to rerun."
    cd "${output_dir}" || exit
    rm -f ./*.finished*
}

function render_inputs() {
    echo "Version: ${RENDER_VERSION}"
    echo "This script should render the Rmd files in the list:"
    echo "${inputs}."
    mkdir -p excel figures
    for input in $(echo "${inputs}" | perl -pe "tr/:/ /"); do
        base=$(basename "$input" .Rmd)
        finished="${base}.finished"
        if [[ -f "${finished}" ]]; then
            echo "The file: ${finished} already exists, skipping this input."
        else
            echo "Rendering: ${input}"
            Rscript -e "hpgltools::renderme('${input}', 'html_document')" | tee -a "${base}.log"
            if [[ "$?" -ne 0 ]]; then
                echo "The Rscript failed."
            else
                echo "The Rscript completed."
                touch "${finished}"
            fi
        fi
    done
}


for arg in "$@"; do
    shift
    case "$arg" in
        '--input') set -- "$@" '-i' ;;
        '--clean') set -- "$@" '-c' ;;
        *) set -- "$@" "$arg" ;;
    esac
done
# Default behavior
number=0; rest=false; ws=false
# Parse short options
OPTIND=1
while getopts "ch:i:" opt; do
    case "$opt" in
        'c') cleanup
           exit 0;;
        'h') usage
           exit 0;;
        'i') inputs=$OPTARG
             render_inputs
             exit 0;;
        *) usage
           exit 1;;
    esac
done
shift $(expr $OPTIND - 1) # remove options from positional parameters

## If -i is not provided, then we are not working from within the container
## and so will not create a directory from within the /output bind mount.

output_dir="$(date +%Y%m%d%H%M)_outputs"
mkdir -p "${output_dir}"
cd "${output_dir}" || exit
## DEFAULT_INPUT is provided in the yml file.
inputs="${DEFAULT_INPUT}"
echo "No colon-separated input file(s) given, analyzing the archived data."
rsync -a /data/ .
for i in $(/bin/ls /data/preprocessing/*.tar); do
    untarred=$(cd preprocessing && tar xaf "${i}")
done

if [[ -n "${untarred}" ]]; then
    echo "The tar command appears to have printed some output."
fi
render_inputs
cd "${start}" || exit
rm current_output
ln -s "${output_dir}" current_output
