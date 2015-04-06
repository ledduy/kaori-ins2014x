#!/usr/bin/env python
import fastcluster;
#fastcluster.kmeans("/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS/INS2013/hesaff_rootsift_noangle_cluster/akmeans_2000000_100000000_50/Clustering_l2_2000000_100000000_128_50it.hdf5",'/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS/INS2013/hesaff_rootsift_noangle_cluster/hesaff_rootsift_noangle100000000_128D.hdf5',2000000,50);

#param1: path to file codebook after training
#param2: path to file feature (100M keypoints)
#param3: number of codewords (1M)
#param4: number of iterations (1 iteration ~ 1 hour --> 50 iterations --> total: 2 days) - ko  nen giam con so nay vi co the se anh huong perf

fastcluster.kmeans("/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS/INS2013/vgg_hesaff_rootsift_noangle_cluster/akmeans_1000000_100000000_50/Clustering_l2_1000000_100000000_128_50it.hdf5",'/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS/INS2013/vgg_hesaff_rootsift_noangle_cluster/vgg_hesaff_rootsift_noangle100000000_128D.hdf5',1000000,50);

