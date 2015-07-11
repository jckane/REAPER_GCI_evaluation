###########################################################
#
# Makefile for GCI REAPER STUDY
#
###########################################################

OCTAVE_CMD=$(shell which octave)
Rscript_CMD=$(shell which Rscript)

ifeq ($(OCTAVE_CMD),)
$(error octave not available, please install along with signal and tsa packages)
endif

ifeq ($(Rscript_CMD),)
$(error Rscript not available, please install base-R from http://cran.us.r-project.org/)
endif

# Standard directories
LOCAL=$(shell pwd)
BUILD=$(LOCAL)/BUILD/
DATA=$(LOCAL)/data/
LIB=$(LOCAL)/lib/

# Additional directories
LIBOCTAVE=$(LIB)octave/
LIBR=$(LIB)R/
AUDIO=$(DATA)audio/
ESPSDATA=$(DATA)ESPS/
EGGDATA=$(DATA)EGG/

# BUILD directories
SEDREAMS=$(BUILD)SEDREAMS/
ESPS=$(BUILD)ESPS/
REAPER=$(BUILD)REAPER/
REFERENCE=$(BUILD)Reference/
METRICS=$(BUILD)Metrics/
RESULTS=$(BUILD)Results/

# Executables
REAPER_CMD:=$(BUILD)/REAPER/BUILD/reaper
SEDREAMS_CMD=extract_GCI_SEDREAMS
REF_CMD=extract_reference_GCIs
METRICS_CMD=compute_Naylor_GCI_metrics
OCTAVE=octave --silent --eval
PLOT_SPEAKER_METRIC=$(LIBR)boxplot_speaker.R
PLOT_VQ_METRIC=$(LIBR)boxplot_VQ.R

AUDIOFILES=$(shell find $(AUDIO) -type f -mindepth 1 -name "*.wav")
ESPSFILES=$(shell find $(ESPSDATA) -type f -mindepth 1 -name "*.pm")
SPEAKERDIR=$(shell find data/audio/ -type d -mindepth 2 -maxdepth 2  | cut -d/ -f 4,5 | grep -v readVQ)
VQDIR=$(shell find data/audio/ -type d -mindepth 3  | cut -d/ -f 5,6)

SPEAKERS=$(addprefix $(REAPER), $(SPEAKERDIR))
SPEAKERS+=$(addprefix $(ESPS), $(SPEAKERDIR))
SPEAKERS+=$(addprefix $(SEDREAMS), $(SPEAKERDIR))
VQS=$(addprefix $(REAPER)readVQ/, $(VQDIR))
VQS+=$(addprefix $(ESPS)readVQ/, $(VQDIR))
VQS+=$(addprefix $(SEDREAMS)readVQ/, $(VQDIR))

SPEAKER_METRICS_TABLE=$(RESULTS)metrics_by_speaker.csv
VQ_METRICS_TABLE=$(RESULTS)metrics_by_VQ.csv

# R packages
R_INSTALL_CMD=R CMD INSTALL
R_LIBRARY=$(BUILD)R_library/
R_PACKAGES=ggplot2_1.0.1.tar.gz
R_PACKAGES+=reshape2_1.4.1.tar.gz
R_PACKAGE_TARGETS:=$(addprefix $(R_LIBRARY), $(R_PACKAGES))
R_CRAN=http://cran.us.r-project.org/src/contrib

# GCI targets
REAPER_GCI:=$(patsubst $(AUDIO)%.wav, $(REAPER)%.csv, $(AUDIOFILES))
ESPS_GCI:=$(patsubst $(ESPSDATA)%.pm, $(ESPS)%.csv, $(ESPSFILES))
SEDREAMS_GCI:=$(patsubst $(AUDIO)%.wav, $(SEDREAMS)%.csv, $(AUDIOFILES))
REF_GCI:=$(patsubst $(AUDIO)%.wav, $(REFERENCE)%.csv, $(AUDIOFILES))

# Other targets
SPEAKER_METRICS:=$(patsubst $(BUILD)%, $(METRICS)%/GCI_metrics.csv,$(SPEAKERS))
VQ_METRICS:=$(patsubst $(BUILD)%, $(METRICS)%/GCI_metrics.csv,$(VQS))
PLOT_SPEAKER_METRICS:=$(RESULTS)GCI_metrics_speaker_level.pdf
PLOT_VQ_METRICS:=$(RESULTS)GCI_metrics_VQ_level.pdf

# Algorithm settings
min_f0=50
max_f0=500

all: $(R_PACKAGE_TARGETS) $(REAPER_CMD) $(REAPER_GCI) $(ESPS_GCI) $(REF_GCI) $(SEDREAMS_GCI) $(SPEAKER_METRICS) $(VQ_METRICS) $(PLOT_SPEAKER_METRICS) $(PLOT_VQ_METRICS)

#########################
# Fetch R packages and compile
#########################

$(R_PACKAGE_TARGETS):
	@[ -d $(@D) ] || mkdir -p $(@D)
	@echo "Downloading $@"
	@curl $(R_CRAN)/$(notdir $@) -o $@
	@$(R_INSTALL_CMD) -l $(R_LIBRARY) $@


#########################
# Compile REAPER
#########################

$(REAPER_CMD):
	@[ -d $(BUILD) ] || mkdir -p $(BUILD)
	@echo "[INFO] Fetching REAPER code"
	@git clone https://github.com/google/REAPER.git
	@mv $(LOCAL)/REAPER/ $(BUILD)/REAPER/
	@[ -d $(@D) ] || mkdir -p $(@D)
	@echo "[INFO] Compiling REAPER code"
	@cd $(BUILD)REAPER/BUILD/; cmake ..; make; cd $(LOCAL)

#########################
# Compute GCIs
#########################


$(REAPER_GCI): $(REAPER)%.csv : $(AUDIO)%.wav
	@[ -d $(@D) ] || mkdir -p $(@D)
	@echo "[INFO] REAPER GCI compute:    $(notdir $@)"
	@$(REAPER_CMD) -i $< -p $@.tmp -a -m $(min_f0) -x $(max_f0)
	@cat $@.tmp | sed -e '1,7d' | cut -d " " -f 1 > $@
	@rm $@.tmp

$(ESPS_GCI): $(ESPS)%.csv : $(ESPSDATA)%.pm
	@[ -d $(@D) ] || mkdir -p $(@D)
	@echo "[INFO] ESPS GCI compute:    $(notdir $@)"
	@cat $< | awk --field-searator="\\t" '{print $$2}' > $@

$(SEDREAMS_GCI): $(SEDREAMS)%.csv : $(AUDIO)%.wav
	@[ -d $(@D) ] || mkdir -p $(@D)
	@echo "SEDREAMS GCI compute:    $(notdir $@)"
	@cd $(LIBOCTAVE); $(OCTAVE) "$(SEDREAMS_CMD)('$<','$@')"; cd $(LOCAL)

$(REF_GCI): $(REFERENCE)%.csv : $(AUDIO)%.wav
	@[ -d $(@D) ] || mkdir -p $(@D)
	@echo "[INFO] Reference GCI compute:    $(notdir $@)"
	@cd $(LIBOCTAVE); $(OCTAVE) "$(REF_CMD)('$<','$@')"; cd $(LOCAL)

########################################
# Compute metrics at the speaker level
########################################

$(SPEAKER_METRICS): 
	@[ -d $(@D) ] || mkdir -p $(@D)
	@[ -d $(RESULTS) ] || mkdir -p $(RESULTS)
	@echo "Computing speaker-level metrics:    $@"
	@cd $(LIBOCTAVE); $(OCTAVE) "$(METRICS_CMD)('$@')"; cd $(LOCAL)
	@touch $(SPEAKER_METRICS_TABLE)
	@echo $(subst $(METRICS), ,$(subst /GCI_metrics.csv,,$@)) > file_name.tmp
	@cat $@ | sed '1d' > metrics.tmp
	@paste -d, file_name.tmp metrics.tmp >> $(SPEAKER_METRICS_TABLE)
	@rm file_name.tmp
	@rm metrics.tmp

$(VQ_METRICS): 
	@[ -d $(@D) ] || mkdir -p $(@D)
	@[ -d $(RESULTS) ] || mkdir -p $(RESULTS)
	@echo "Computing speaker-level metrics:    $@"
	@cd $(LIBOCTAVE); $(OCTAVE) "$(METRICS_CMD)('$@')"; cd $(LOCAL)
	@touch $(VQ_METRICS_TABLE)
	@echo $(subst $(METRICS), ,$(subst /GCI_metrics.csv,,$@)) > file_name.tmp
	@cat $@ | sed '1d' > metrics.tmp
	@paste -d, file_name.tmp metrics.tmp >> $(VQ_METRICS_TABLE)
	@rm file_name.tmp
	@rm metrics.tmp

########################################
# Do plotting 
########################################

$(PLOT_SPEAKER_METRICS):
	@[ -d $(@D) ] || mkdir -p $(@D)
	@echo "Plotting GCI metrics by speaker"
	@$(Rscript_CMD) $(PLOT_SPEAKER_METRIC) $(SPEAKER_METRICS_TABLE) $(R_LIBRARY) $@

$(PLOT_VQ_METRICS):
	@[ -d $(@D) ] || mkdir -p $(@D)
	@echo "Plotting GCI metrics by speaker"
	@$(Rscript_CMD) $(PLOT_VQ_METRIC) $(VQ_METRICS_TABLE) $(R_LIBRARY) $(RESULTS)


########################################
# Compute ANOVA stats
########################################



clean:
	rm -rf ./BUILD

