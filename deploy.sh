#!/bin/sh

#SBATCH --exclusive
#SBATCH -N 1
#SBATCH --account=astro       # The account name for the job.
#SBATCH --job-name=NNspectra  # The job name.
#SBATCH --time=10:00:00       # The time the job will take to run 
#SBATCH --array 1-20
N_JOBS=20

module load julia

#make a local temp directory for the cache
TMPDIR=`mktemp -d`
mkdir "$TMPDIR/compiled"
# copy the cache to the temp directory
#rsync -au "$JULIA_DEPOT_PATH/compiled/v1.0" "$TMPDIR/compiled/" 
#set the temp directory as the first depot so any (re)compilation 
#will happen there and not interfere with other jobs
export JULIA_DEPOT_PATH="$TMPDIR:$JULIA_DEPOT_PATH" 

CAT_FILE=one_tenth_of_lamost.csv
DATA_DIR=/moto/astro/users/ajw2207/LAMOST_spectra
TRAINING_SET=LAMOST_top_1000_snr.csv

OUTDIR=/moto/astro/users/ajw2207/NNspectra/k4_t1000_test
mkdir -p $OUTDIR
time julia -p 24 --compiled-modules=no deploy.jl $CAT_FILE $TRAINING_SET $DATA_DIR $OUTDIR 4 $SLURM_ARRAY_TASK_ID $N_JOBS

OUTDIR=/moto/astro/users/ajw2207/NNspectra/k8_t1000_test
mkdir -p $OUTDIR
time julia -p 24 --compiled-modules=no deploy.jl $CAT_FILE $TRAINING_SET $DATA_DIR $OUTDIR 8 $SLURM_ARRAY_TASK_ID $N_JOBS

OUTDIR=/moto/astro/users/ajw2207/NNspectra/k16_t1000_test
mkdir -p $OUTDIR
time julia -p 24 --compiled-modules=no deploy.jl $CAT_FILE $TRAINING_SET $DATA_DIR $OUTDIR 16 $SLURM_ARRAY_TASK_ID $N_JOBS

echo node $SLURM_ARRAY_TASK_ID finished
                                    
