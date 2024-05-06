#!/bin/bash -l

modelRoot=$1

tempPath=$(dirname "$modelRoot")
period=$(basename "$tempPath")
tempPath2=$(dirname "$tempPath")
simulation=$(basename "$tempPath2")


eejitPath="7006713@eejit.geo.uu.nl:/scratch/depfg/7006713/temp/cmip6_input/$simulation/$period" 
snelliusPath=$modelRoot/cmip6_input
scp -r $eejitPath $snelliusPath