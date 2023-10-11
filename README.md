# Macrophage responses across infection with two L. panamensis strains and drug treatment

This repository contains the recipe, data, etc. used to perform
the various analyses when examining human macrophages infected (or
not), drug treated (or not) with two zymodemes of Leishmania
panamensis.

# Caveats

In two potentially important ways this repository does not
_completely_ meet my definition of a reproducible image:

1.  The recipe explicitly uses the already-built image of
    hpgltools in the parent recipe:
    https://github.com/elsayed-lab/hpgltools_singularity
    This image was digitally signed (by me) and uploaded to the
    singularity hub:
    https://cloud.sylabs.io/library/abelew/hpgltools/hpgltools.sif
    Thus, I am not sure if another person can prove that I didn't do
    some shenanigans inside that parent image.  However, I do clone
    the repository into /hpgltools within the resulting container, so
    one may trivially go into it and look around and see the state of
    the codebase.
2.  In earlier revisions of this and its sibling images, I use an
    explicit git commit of hpgltools to make absolutely certain that
    the resulting image used a known state of that repository.  Given
    that I am using the prebuilt image in #1, that is no longer true.
3.  I didn't add the actual data yet to the repository.  Once the
    manuscript is (close to?) finished, I will perform the git add of
    the 'data/' tarball.
4.  You must (for the moment) assume that I treated the raw data in a
    sane fashion.  Once we have SRA IDs, I will create a recipe/image
    which may be used to explicitly create all the data used here,
    though that image will possibly not include the full installation
    of fastp,fastqc,trimomatic,samtools,freebayes,salmon,hisat,etc... I
    am not sure how I want to handle that yet.

If one is willing to overlook these two caveats, then I think this
recipe nicely meets the definition of a reproducible codebase.  It is
also quite trivial to fix the above at the cost of a (much) longer build
time:

1.  Go into the recipe.yml and change the second line to
    'From: debian:stable' instead of the reference to library:// (oh,
    this image is not using that sylabs image yet, so I guess
    nevermind?)
2.  Change the local/bin/setup_hpgltools.sh so that the variable
    'commit' points to the git commit ID of interest.

# Installation/Usage

1. Clone the repository.
2. run 'make tmrc2_macr.sif' or 'sudo singularity build tmrc2_macr.sif tmrc2_macr.yml'
3. wait a while.
4. The resulting .sif file may be run as a standalone executable.  It
   currently assumes the user set the SINGULARITY_BIND environment
   variable to something like 'SINGULARITY_BIND=.:/output' so that it
   may write its set of rendered html reports to the current working
   directory. Assuming that is true, it will create a new
   tree with a prefix of '$(date +%Y%M)' and put them there.  It also
   copies the input data, sample sheets, etc there for one to play
   with.
