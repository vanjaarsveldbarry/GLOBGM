
module load 2023
module load mpifileutils/0.11.1-gompi-2023a

#To compress the calibration folder
#  iput -rvP /scratch-shared/bvjaarsveld/calibration_round1.tar.gz /nluu14p/home/deposit-pilot/globgm/calibration

#To decompress the calibration folder
srun --partition=genoa --nodes=1 --ntasks-per-node=32 --job-name="interact" --time=01:00:00 --pty bash -i
mpirun -np 10 dtar --progress 3 -c -f /gpfs/scratch1/shared/bvjaarsveld/dir_test.tar /gpfs/scratch1/shared/bvjaarsveld/calibration


cd /projects/prjs1222/globgm_output/calibration
mpirun -np 10 dtar -x -f calibration.tar