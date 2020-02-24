################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Each subdirectory must supply rules for building sources it contributes
RunNMR_orig_170227AM.obj: ../RunNMR_orig_170227AM.c $(GEN_OPTS) $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"/Applications/ti/ccsv6/tools/compiler/ti-cgt-c2000_15.12.1.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="/Applications/ti/ccsv6/tools/compiler/ti-cgt-c2000_15.12.1.LTS/include" --include_path="/Users/ysong/ti/workspace_v6_1_3/uNMR_CCS613/DSP2833x/include" --include_path="/Users/ysong/ti/workspace_v6_1_3/uNMR_CCS613/DSP2833x_common/include" --include_path="/Users/ysong/ti/workspace_v6_1_3/uNMR_CCS613/freeMODBUS/include" --include_path="/Users/ysong/ti/workspace_v6_1_3/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="RunNMR_orig_170227AM.d" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '


