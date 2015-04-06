This if for TiepNV code!

Steps to run:

1. Extract features
extract_hesaffine_rootsift_noangle.m
extract_perdoch_rootsift.m
2. Get a subset of keypoints to build codebook
sampling_feat4clustering_perdoch.m
sampling_feat4clustering_vgg_hesaff.m
3. Build codebooking using AKM
akm.py
4. Do quantization
quantize.m
quantize_check.m
quantize_merge.m

Execute multiple runs:
runme4BoW2013.sh
runme4BoW2014.sh