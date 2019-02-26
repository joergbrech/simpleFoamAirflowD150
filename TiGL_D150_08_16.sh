#!/bin/bash
#SBATCH --partition=hpc3		# partition (queue) 
#SBATCH --nodes=2			# number of nodes	
#SBATCH --ntasks-per-node=32     	# number of cores per node
#SBATCH --ntasks-per-core=1      	# use only real cores
#SBATCH --mem=100G			# memory per node in MB (different units with suffix K|M|G|T)
#SBATCH --time=16:00:00			# total runtime of job allocation (format D-HH:MM:SS; first parts optional)
#SBATCH --output=slurm.%j.out		# filename for STDOUT (%N: nodename, %j: job-ID)
#SBATCH --error=slurm.%j.err		# filename for STDERR

module load openfoam/v1712

### Zum Starten des Jobs mit 'cd' in den Ordner gehen, in dem die Ausgabedateien gespeichert werden sollen, und dort ###
### mit "sbatch Dateiname" den Job starten; dabei den Namen der Kopie dieser Datei angeben.                          ###


### Start job
echo "Starting at "
date

cd $SLURM_SUBMIT_DIR/simpleFoam


### Convert Gmsh Format to OpenFOAM Format
gmshToFoam Mesh_Groups.msh >>log.ConvertMsh2OpenFOAM
cd ..
rm $SLURM_SUBMIT_DIR/simpleFoam/constant/polyMesh/boundary
cp boundary $SLURM_SUBMIT_DIR/simpleFoam/constant/polyMesh/
cd $SLURM_SUBMIT_DIR/simpleFoam


checkMesh -allGeometry -allTopology >> log.checkMesh


### Make 3D mesh in parallel...
decomposePar >> log.decomposePar
mpirun patchSummary -parallel >> log.patchSummary

### Solve to steady state...
cp system/controlDictStart system/controlDict
cp system/fvSchemesStart system/fvSchemes
cp system/fvSolutionStart system/fvSolution 

mpirun simpleFoam -parallel >> log.simpleFoam	


cp system/controlDictStandard system/controlDict
cp system/fvSchemesStandard system/fvSchemes
cp system/fvSolutionStandard system/fvSolution 

mpirun simpleFoam -parallel >> log.simpleFoam

cp system/controlDictAverage system/controlDict

mpirun simpleFoam -parallel >> log.simpleFoam

### Reconstruct data and convert to VTK
reconstructParMesh -constant -mergeTol 1E-06 >> log.reconstructParMesh
reconstructPar -latestTime >> log.reconstructPar
foamToVTK -ascii >> log.foamToVTK

echo "Run completed at "
date

