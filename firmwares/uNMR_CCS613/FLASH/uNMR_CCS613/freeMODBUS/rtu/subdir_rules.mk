################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Each subdirectory must supply rules for building sources it contributes
uNMR_CCS613/freeMODBUS/rtu/mbcrc.obj: ../uNMR_CCS613/freeMODBUS/rtu/mbcrc.c $(GEN_OPTS) $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"D:/ti/ccsv6/tools/compiler/ti-cgt-c2000_15.12.1.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="D:/ti/ccsv6/tools/compiler/ti-cgt-c2000_15.12.1.LTS/include" --include_path="D:/SVN/unmr/102009261/uNMR_CCS613/DSP2833x/include" --include_path="D:/SVN/unmr/102009261/uNMR_CCS613/DSP2833x_common/include" --include_path="D:/SVN/unmr/102009261/uNMR_CCS613/freeMODBUS/include" --include_path="D:/SVN/unmr/102009261/uNMR_CCS613/INCLUDE" -g --define=FLASH --diag_warning=225 --diag_wrap=off --display_error_number --preproc_with_compile --preproc_dependency="uNMR_CCS613/freeMODBUS/rtu/mbcrc.d" --obj_directory="uNMR_CCS613/freeMODBUS/rtu" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

uNMR_CCS613/freeMODBUS/rtu/mbrtu.obj: ../uNMR_CCS613/freeMODBUS/rtu/mbrtu.c $(GEN_OPTS) $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"D:/ti/ccsv6/tools/compiler/ti-cgt-c2000_15.12.1.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="D:/ti/ccsv6/tools/compiler/ti-cgt-c2000_15.12.1.LTS/include" --include_path="D:/SVN/unmr/102009261/uNMR_CCS613/DSP2833x/include" --include_path="D:/SVN/unmr/102009261/uNMR_CCS613/DSP2833x_common/include" --include_path="D:/SVN/unmr/102009261/uNMR_CCS613/freeMODBUS/include" --include_path="D:/SVN/unmr/102009261/uNMR_CCS613/INCLUDE" -g --define=FLASH --diag_warning=225 --diag_wrap=off --display_error_number --preproc_with_compile --preproc_dependency="uNMR_CCS613/freeMODBUS/rtu/mbrtu.d" --obj_directory="uNMR_CCS613/freeMODBUS/rtu" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '


