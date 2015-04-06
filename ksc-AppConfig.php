<?php

/**
 * 		@file 	ksc-AppConfig.php
 * 		@brief 	Configuration file for KAORI- App.
 *		@author Duy-Dinh Le (ledduy@gmail.com, ledduy@ieee.org).
 *
 * 		Copyright (C) 2010-2014 Duy-Dinh Le.
 * 		All rights reserved.
 * 		Last update	: 03 Aug 2014.
 */

////////////////// HOW TO CUSTOMIZE /////////////////////////

//--> Look for *** CHANGED *** and make appropriate changes
// $gszRootBenchmarkDir = "/net/sfv215/export/raid4/ledduy/XXX"; // *** CHANGED ***
// $gszRootBenchmarkExpDir = $gszRootBenchmarkDir; --> change it if experiment dir is on different server for load balancing. 
// $gszSGEScriptDir = "/net/per900b/raid0/ledduy/XXX"; // *** CHANGED ***
// $gszTmpDir = "/net/dl380g7a/export/ddn11a6/ledduy/tmp"; // *** CHANGED ***

//--> max frame size: 500x500
//$gnHavingResized = 1;
//$gnMaxFrameWidth = 500; // *** CHANGED ***
//$gnMaxFrameHeight = 500; // *** CHANGED ***

//////////////////////////////////////////////////////////////

/////////////////// IMPORTANT PARAMS /////////////////////////

//--> max frame size: 500x500
// $gnHavingResized = 1;
// $gnMaxFrameWidth = 500; // *** CHANGED ***
// $gnMaxFrameHeight = 500; // *** CHANGED ***

//--> BOW params -- SHOULD NOT CHANGE
// $nNumClusters = 500;
// $szKMeansMethod = 'elkan';

// $szTrialName = sprintf("Soft-%d-VL2", $nNumClusters);
//printf("### Trial Name: [%s]\n", $szTrialName);

// $nMaxCodeBookSize = $nNumClusters*2;

//--> kaori-lib, libsvm291 now are subdirs 

/////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////
// Import kaori-lib tools
require_once "kaori-lib/kl-AppConfig.php";
require_once "kaori-lib/kl-IOTools.php";
require_once "kaori-lib/kl-MiscTools.php";
require_once "kaori-lib/kl-DataProcessingTools.php";
require_once "kaori-lib/kl-SVMTools.php";

// Global vars

// this is used for csv-style file
$gszDelim = "#$#";


//////////////////// THIS PART FOR CUSTOMIZATION ////////////////////

// Root of a benchmark, e.g. trecvid-ins-2013
$gszRootBenchmarkDir = "/net/per610a/export/das11f/ledduy/trecvid-ins-2014"; // *** CHANGED ***

// Dir for experiments --> for load balancing, use another server
$gszRootBenchmarkExpDir = $gszRootBenchmarkDir; // *** CHANGED ***

// Dir for php code
$gszSGEScriptDir = "/net/per900c/raid0/ledduy/github-projects/kaori-ins2014x"; // *** CHANGED *** 06Apr2015

//*** SHOULD NOT CHANGE *****
// Dir for .sh script
$gszScriptBinDir = "/net/per900c/raid0/ledduy/binCmd/kaori-ins2014x"; // *** CHANGED *** 06Apr2015
makedir($gszScriptBinDir);

// TmpDir
$gszTmpDir = "/local/ledduy";
if(!file_exists($gszTmpDir))
{
	$gszTmpDir = "/net/dl380g7a/export/ddn11a6/ledduy/tmp/kaori-ins2014x"; // *** CHANGED *** 06Apr2015
	makeDir($gszTmpDir);
}

//////////////////// MIGHT NOT BE USED BUT KEEP FOR REFERENCE /////////////////// // new 02Aug2014

// LUT for annotaton data used in collaborative annotation and NIST ground truth
$garLabelList = array("P" => "Pos", "N" => "Neg", "S" => "Skipped");
$garInvLabelList = array("Pos" => "P", "Neg" => "N", "Skipped" => "S");
$garLabelValList = array(1 => "Pos", -1 => "Neg", 0 => "Skipped");
$garInvLabelValList = array("Pos" => 1, "Neg" => -1);
$garLabelMapList = array(1 => "P", -1 => "N", 0 => "S");
$gszPosLabel = "Pos";
$gszNegLabel = "Neg";


// SVM configs
$gszSVMTrainApp = sprintf("libsvm291/svm-train");
$gszSVMPredictScoreApp = sprintf("libsvm291/svm-predict-score");
$gszGridSearchApp = sprintf("libsvm291/grid.py");
$gszSVMSelectSubSetApp = sprintf("libsvm291/subset.py");
$gszSVMScaleApp = sprintf("libsvm291/svm-scale");

// Will be overriden later
$gfPosWeight = 1000;
$gfNegWeight = 1;
$gnMemSize = 1000;
$gnStartC = 0;
$gnEndC = 6;
$gnStepC = 2;
$gnStartG = -10;
$gnEndG = 0;
$gnStepG = 2;

$gszFeatureFormat = "dvf";

// Dir for feature config files --> GLOBAL features
$gszFeatureConfigDir = "BaselineFeatureConfig";

// !!! IMPORTANT PARAMS !!!
// used with BOW features
$gnHavingResized = 1;
$gnMaxFrameWidth = 500; // *** CHANGED ***
$gnMaxFrameHeight = 500; // *** CHANGED ***
$gszResizeOption = sprintf("-resize '%sx%s>'", $gnMaxFrameWidth, $gnMaxFrameHeight); // to ensure W is the width after shrinking

/// !!! IMPORTANT PARAM !!!
$nNumClusters = 4000;
$szKMeansMethod = 'elkan';

$szTrialName = sprintf("Soft-%d", $nNumClusters);
//printf("### Trial Name: [%s]\n", $szTrialName);

$nMaxCodeBookSize = $nNumClusters*2;

// feature extraction app
$garAppConfig["BL_FEATURE_EXTRACT_APP"] = "FeatureExtractorCmd/FeatureExtractorCmd";

// UvA's color descriptor code
$garAppConfig["RAW_COLOR_SIFF_APP"] = "colordescriptor30/x86_64-linux-gcc/colorDescriptor ";

// VLFEAT
$garAppConfig["RAW_VLFEAT_DIR"] = "vlfeat-0.9.14"; //--> move to subdir

// Oxford VGG's code
$garAppConfig["RAW_AFF_COV_SIFF_APP"] = "aff.cov.sift/extract_features_64bit.ln";

$garAppConfig["SASH_KEYPOINT_TOOL_BOW_L2_APP"] = "sashKeyPointTool/sashKeyPointTool-nsc-BOW-L2";


//////////////////// END FOR CUSTOMIZATION ////////////////////

require_once "ksc-AppConfigForProject.php";

?>