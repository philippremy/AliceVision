## AliceVision
## Utilities software

# Software PROPERTY FOLDER is 'Software/Utils'
set(FOLDER_SOFTWARE_UTILS "Software/Utils")


if(ALICEVISION_HAVE_CUDA)
    alicevision_add_software(aliceVision_hardwareResources
        SOURCE main_hardwareResources.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_gpu
              Boost::program_options
    )
endif()

if(ALICEVISION_BUILD_SFM)
    # Uncertainty
    if(ALICEVISION_HAVE_UNCERTAINTYTE)
        alicevision_add_software(aliceVision_computeUncertainty
            SOURCE main_computeUncertainty.cpp
            FOLDER ${FOLDER_SOFTWARE_UTILS}
            LINKS aliceVision_sfm
                  aliceVision_system
                  aliceVision_cmdline
                  ${CUDA_LIBRARIES}
                  ${CUDA_CUBLAS_LIBRARIES}
                  ${CUDA_cusparse_LIBRARY}
                  ${UNCERTAINTYTE_LIBRARY}
                  Boost::program_options
            INCLUDE_DIRS ${UNCERTAINTYTE_INCLUDE_DIR}
        )
        # message(warning "UNCERTAINTYTE_LIBRARY: ${UNCERTAINTYTE_LIBRARY}")
        # message(warning "CUDA_LIBRARIES: ${CUDA_LIBRARIES}")
        # message(warning "CUDA_CUBLAS_LIBRARIES: ${CUDA_CUBLAS_LIBRARIES}")
        # message(warning "CUDA_cusparse_LIBRARY: ${CUDA_cusparse_LIBRARY}")
    endif()

    alicevision_add_software(aliceVision_imageProcessing 
        SOURCE main_imageProcessing.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_sensorDB
              aliceVision_image
              aliceVision_feature
              aliceVision_sfm
              aliceVision_sfmData
              aliceVision_sfmDataIO
              aliceVision_lensCorrectionProfile
              ${Boost_LIBRARIES}
    )

    if(ALICEVISION_HAVE_OPENCV)
        target_link_libraries(aliceVision_imageProcessing_exe PRIVATE ${OpenCV_LIBS})
    endif()

    alicevision_add_software(aliceVision_importMiddlebury
        SOURCE main_importMiddlebury.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_numeric
              aliceVision_geometry
              aliceVision_sfmData
              aliceVision_sfmDataIO
              aliceVision_system
              aliceVision_cmdline
              ${Boost_LIBRARIES}
    )

    # Voctree creation
    alicevision_add_software(aliceVision_voctreeCreation
        SOURCE main_voctreeCreation.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_voctree
              aliceVision_feature
              aliceVision_sfmData
              aliceVision_sfmDataIO
              aliceVision_system
              aliceVision_cmdline
              Boost::program_options
    )

    # Voctree query utility
    alicevision_add_software(aliceVision_voctreeQueryUtility
        SOURCE main_voctreeQueryUtility.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_voctree
              aliceVision_sfm
              aliceVision_sfmData
              aliceVision_sfmDataIO
              aliceVision_system
              aliceVision_cmdline
              Boost::program_options
              Boost::boost
              Boost::timer
    )

    # Voctree statistics
    alicevision_add_software(aliceVision_voctreeStatistics
        SOURCE main_voctreeStatistics.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_voctree
              aliceVision_sfmData
              aliceVision_system
              aliceVision_cmdline
              aliceVision_sfmDataIO
              Boost::program_options
              Boost::boost
    )

    # Frustrum filtering
    alicevision_add_software(aliceVision_frustumFiltering
        SOURCE main_frustumFiltering.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_feature
              aliceVision_matchingImageCollection
              aliceVision_sfm
              aliceVision_sfmData
              aliceVision_sfmDataIO
              Boost::program_options
    )

    # Transform rig
    if(ALICEVISION_HAVE_ALEMBIC)
        alicevision_add_software(aliceVision_rigTransform
            SOURCE main_rigTransform.cpp
            FOLDER ${FOLDER_SOFTWARE_UTILS}
            LINKS aliceVision_sfmData
                  aliceVision_sfmDataIO
                  aliceVision_localization
                  aliceVision_dataio
                  aliceVision_rig
                  aliceVision_system
                  aliceVision_cmdline
                  Boost::program_options
        )
    endif()

    # SfM quality evaluation
    # - quality comparison against a GT camera path (MultiView Evaluation dataset)
    alicevision_add_software(aliceVision_qualityEvaluation
        SOURCE main_qualityEvaluation.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_feature
              aliceVision_sfmData
              aliceVision_sfmDataIO
              Boost::program_options
    )

    # SfM alignment
    alicevision_add_software(aliceVision_sfmAlignment
        SOURCE main_sfmAlignment.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_feature
              aliceVision_sfm
              aliceVision_sfmData
              aliceVision_sfmDataIO
              Boost::program_options
    )

    # SfM transfer
    alicevision_add_software(aliceVision_sfmTransfer
        SOURCE main_sfmTransfer.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_feature
              aliceVision_sfm
              aliceVision_sfmData
              aliceVision_sfmDataIO
              Boost::program_options
    )

    # SfM transform
    alicevision_add_software(aliceVision_sfmTransform
        SOURCE main_sfmTransform.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_feature
              aliceVision_sfm
              aliceVision_sfmData
              aliceVision_sfmDataIO
              Boost::program_options
    )

    # SfM to rig
    alicevision_add_software(aliceVision_sfmToRig
        SOURCE main_sfmToRig.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_sfmData
              aliceVision_sfmDataIO
              Boost::program_options
    )

    # SfM Merge
    alicevision_add_software(aliceVision_sfmMerge
        SOURCE main_sfmMerge.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_sfmData
              aliceVision_sfmDataIO
              Boost::program_options
    )

    # SfM Regression
    alicevision_add_software(aliceVision_sfmRegression
        SOURCE main_sfmRegression.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_feature
              aliceVision_sfm
              aliceVision_sfmData
              aliceVision_sfmDataIO
              Boost::program_options
    )

    # SfM split reconstructed
    alicevision_add_software(aliceVision_sfmSplitReconstructed
        SOURCE main_sfmSplitReconstructed.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_sfmData
              aliceVision_sfmDataIO
              Boost::program_options
    )

    # SfM color harmonize
    alicevision_add_software(aliceVision_sfmColorHarmonize
        SOURCE main_sfmColorHarmonize.cpp
               sfmColorHarmonize/colorHarmonizeEngineGlobal.cpp # TODO
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_image
              aliceVision_feature
              aliceVision_kvld
              aliceVision_sfm
              aliceVision_sfmData
              aliceVision_sfmDataIO
              aliceVision_colorHarmonization
              Coin::Clp
              Coin::CoinUtils
              Coin::Osi
              Boost::program_options
              Boost::boost
              Boost::timer
              ${LEMON_LIBRARY}
    )

    # Keyframe selection
    # - export keyframes from video files / image sequence directories
    if(ALICEVISION_HAVE_OPENCV)
        alicevision_add_software(aliceVision_keyframeSelection
            SOURCE main_keyframeSelection.cpp
            FOLDER ${FOLDER_SOFTWARE_UTILS}
            LINKS aliceVision_system
                  aliceVision_cmdline
                  aliceVision_image
                  aliceVision_keyframe
                  ${OPENIMAGEIO_LIBRARIES}
                  Boost::program_options
        )
    endif()


    # Print distances between 3D objects
    alicevision_add_software(aliceVision_sfmDistances
        SOURCE main_sfmDistances.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_sfm
              aliceVision_sfmData
              aliceVision_sfmDataIO
              aliceVision_system
              aliceVision_cmdline
              ${Boost_LIBRARIES}
    )

    # Perform color chart detection
    if(ALICEVISION_HAVE_OPENCV_CONTRIB)
        alicevision_add_software(aliceVision_colorCheckerDetection
            SOURCE main_colorCheckerDetection.cpp
            FOLDER ${FOLDER_SOFTWARE_UTILS}
            LINKS aliceVision_system
                  aliceVision_cmdline
                  aliceVision_sfmData
                  aliceVision_sfmDataIO
                  Boost::program_options
                  ${OpenCV_LIBS} # opencv_core  opencv_imgproc  opencv_video  opencv_imgcodecs  opencv_videoio  opencv_features2d  opencv_xfeatures2d
                  opencv_mcc
        )

        # Apply calibration
        alicevision_add_software(aliceVision_applyCalibration
            SOURCE main_applyCalibration.cpp
            FOLDER ${FOLDER_SOFTWARE_UTILS}
            LINKS aliceVision_system
                  aliceVision_cmdline
                  aliceVision_sfmData
                  aliceVision_sfmDataIO
                  aliceVision_camera
                  Boost::program_options
        )
    endif()


    # Perform color correction
    if(ALICEVISION_HAVE_OPENCV_CONTRIB)
        alicevision_add_software(aliceVision_colorCheckerCorrection
            SOURCE main_colorCheckerCorrection.cpp
            FOLDER ${FOLDER_SOFTWARE_UTILS}
            LINKS aliceVision_system
                  aliceVision_cmdline
                  aliceVision_sfmData
                  aliceVision_sfmDataIO
                  Boost::program_options
                  ${OpenCV_LIBS} # opencv_core  opencv_imgproc  opencv_video  opencv_imgcodecs  opencv_videoio  opencv_features2d  opencv_xfeatures2d
                  opencv_mcc
        )
    endif()

endif() # ALICEVISION_BUILD_SFM

if (ALICEVISION_BUILD_PANORAMA)
    # Split 360 images in input in order to export square images
    alicevision_add_software(aliceVision_split360Images
        SOURCE main_split360Images.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_numeric
              aliceVision_image
              aliceVision_panorama
              aliceVision_sfmData
              aliceVision_sfmDataIO
              aliceVision_camera
              ${OPENIMAGEIO_LIBRARIES}
              Boost::program_options
    )
endif()

if(ALICEVISION_BUILD_MVS)

    # Lighting estimation from picture, albedo and geometry
    alicevision_add_software(aliceVision_lightingEstimation
        SOURCE main_lightingEstimation.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_numeric
              aliceVision_sfmData
              aliceVision_sfmDataIO
              aliceVision_mvsUtils
              aliceVision_image
              aliceVision_lightingEstimation
              ${Boost_LIBRARIES}
    )


    # Lighting estimation from picture, albedo and geometry
    alicevision_add_software(aliceVision_generateSampleScene
        SOURCE main_generateSampleScene.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_numeric
              aliceVision_sfmData
              aliceVision_sfmDataIO
              aliceVision_mvsUtils
              ${Boost_LIBRARIES}
    )

    # Merge two meshes
    alicevision_add_software(aliceVision_mergeMeshes
        SOURCE main_mergeMeshes.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_numeric
              Geogram::geogram
              ${Boost_LIBRARIES}
    )

    # Mesh Remove Unseen Faces
    alicevision_add_software(aliceVision_meshRemoveUnseenFaces
        SOURCE main_meshRemoveUnseenFaces.cpp
        FOLDER ${FOLDER_SOFTWARE_UTILS}
        LINKS aliceVision_system
              aliceVision_cmdline
              aliceVision_mvsUtils
              aliceVision_mesh
              aliceVision_sfmData
              aliceVision_sfmDataIO
              Boost::program_options
    )

    ### DISABLE UNTIL DEPTHMAP IS RE-IMPLEMENTED!!! ###
    # Select Connected Views
    #alicevision_add_software(aliceVision_selectConnectedViews
    #    SOURCE main_selectConnectedViews.cpp
    #    FOLDER ${FOLDER_SOFTWARE_UTILS}
    #    LINKS aliceVision_system
    #          aliceVision_cmdline
    #          aliceVision_mvsData
    #          aliceVision_mvsUtils
    #          aliceVision_depthMap
    #          aliceVision_sfmData
    #          aliceVision_sfmDataIO
    #          Boost::program_options
    #)

endif() # ALICEVISION_BUILD_MVS
