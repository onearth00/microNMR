################################################################################
# Automatically-generated file. Do not edit!
################################################################################

SHELL = cmd.exe

# Each subdirectory must supply rules for building sources it contributes
SOURCE/ADS1248\ .obj: ../SOURCE/ADS1248\ .c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="SOURCE/ADS1248 .d" --obj_directory="SOURCE" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

SOURCE/PLL.obj: ../SOURCE/PLL.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="SOURCE/PLL.d" --obj_directory="SOURCE" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

SOURCE/RunNMR.obj: ../SOURCE/RunNMR.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="SOURCE/RunNMR.d" --obj_directory="SOURCE" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

SOURCE/asic.obj: ../SOURCE/asic.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="SOURCE/asic.d" --obj_directory="SOURCE" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

SOURCE/cpu_timer.obj: ../SOURCE/cpu_timer.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="SOURCE/cpu_timer.d" --obj_directory="SOURCE" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

SOURCE/gpio_init.obj: ../SOURCE/gpio_init.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="SOURCE/gpio_init.d" --obj_directory="SOURCE" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

SOURCE/main.obj: ../SOURCE/main.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="SOURCE/main.d" --obj_directory="SOURCE" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

SOURCE/nmr.obj: ../SOURCE/nmr.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="SOURCE/nmr.d" --obj_directory="SOURCE" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

SOURCE/nmr_plsq.obj: ../SOURCE/nmr_plsq.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="SOURCE/nmr_plsq.d" --obj_directory="SOURCE" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '

SOURCE/tempcontoller.obj: ../SOURCE/tempcontoller.c $(GEN_OPTS) | $(GEN_HDRS)
	@echo 'Building file: $<'
	@echo 'Invoking: C2000 Compiler'
	"C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/bin/cl2000" -v28 -ml -mt --float_support=fpu32 -Ooff --include_path="C:/ti/ccsv7/tools/compiler/ti-cgt-c2000_16.9.3.LTS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/DSP2833x_common/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/freeMODBUS/include" --include_path="C:/Users/ytang12/workspace_v7/uNMR_CCS613/INCLUDE" --advice:performance=all -g --define=FLASH --display_error_number --diag_warning=225 --diag_wrap=off --preproc_with_compile --preproc_dependency="SOURCE/tempcontoller.d" --obj_directory="SOURCE" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: $<'
	@echo ' '


