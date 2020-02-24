################################################################################
# Automatically-generated file. Do not edit!
################################################################################

SHELL = cmd.exe

# Each subdirectory must supply rules for building sources it contributes
freeMODBUS/mb.obj: ../freeMODBUS/mb.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="freeMODBUS/mb.d" --obj_directory="freeMODBUS" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

freeMODBUS/portevent.obj: ../freeMODBUS/portevent.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="freeMODBUS/portevent.d" --obj_directory="freeMODBUS" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

freeMODBUS/portserial.obj: ../freeMODBUS/portserial.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="freeMODBUS/portserial.d" --obj_directory="freeMODBUS" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

freeMODBUS/porttimer.obj: ../freeMODBUS/porttimer.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="freeMODBUS/porttimer.d" --obj_directory="freeMODBUS" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '


