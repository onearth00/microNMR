################################################################################
# Automatically-generated file. Do not edit!
################################################################################

SHELL = cmd.exe

# Each subdirectory must supply rules for building sources it contributes
freeMODBUS/rtu/mbcrc.obj: ../freeMODBUS/rtu/mbcrc.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" -g --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="freeMODBUS/rtu/mbcrc.d" --obj_directory="freeMODBUS/rtu" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

freeMODBUS/rtu/mbrtu.obj: ../freeMODBUS/rtu/mbrtu.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" -g --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="freeMODBUS/rtu/mbrtu.d" --obj_directory="freeMODBUS/rtu" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '


