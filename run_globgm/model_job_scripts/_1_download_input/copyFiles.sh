#!/bin/bash -l

modelRoot=$1

tempPath=$(dirname "$modelRoot")
simulation=$(basename "$modelRoot")


eejitPath="7006713@eejit.geo.uu.nl:/scratch/depfg/7006713/temp/cmip6_input/$simulation" 
snelliusPath=$modelRoot/cmip6_input
scp -r $eejitPath $snelliusPath