###########################################################
#
# Makefile for GCI REAPER STUDY
#
###########################################################

# TBD: add checks for octave and for Rscript

# Standard directories
LOCAL=$(shell pwd)
BUILD=$(LOCAL)/BUILD/
DATA=$(LOCAL)/data/
LIB=$(LOCAL)/lib/

# Additional directories
LIBOCTAVE=$(LIB)octave/
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

# TBD: remove the ARCTIC!!
# TBD: start with just 10 files to analyse
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

# GCI targets
REAPER_GCI:=$(patsubst $(AUDIO)%.wav, $(REAPER)%.csv, $(AUDIOFILES))
ESPS_GCI:=$(patsubst $(ESPSDATA)%.pm, $(ESPS)%.csv, $(ESPSFILES))
SEDREAMS_GCI:=$(patsubst $(AUDIO)%.wav, $(SEDREAMS)%.csv, $(AUDIOFILES))
REF_GCI:=$(patsubst $(AUDIO)%.wav, $(REFERENCE)%.csv, $(AUDIOFILES))
SPEAKER_METRICS:=$(patsubst $(BUILD)%, $(METRICS)%/GCI_metrics.csv,$(SPEAKERS))
VQ_METRICS:=$(patsubst $(BUILD)%, $(METRICS)%/GCI_metrics.csv,$(VQS))

# Algorithm settings
min_f0=50
max_f0=500

all: $(REAPER_CMD) $(REAPER_GCI) $(ESPS_GCI) $(REF_GCI) $(SPEAKER_METRICS) $(VQ_METRICS)

reaper: $(REAPER_CMD)
# TBD: Need to compile R packages!

#########################
# Compile REAPER
#########################

$(REAPER_CMD):
	@[ -d $(BUILD) ] || mkdir -p $(BUILD)
	@echo "Fetching REAPER code"
	@git clone https://github.com/google/REAPER.git
	@mv $(LOCAL)/REAPER/ $(BUILD)/REAPER/
	@[ -d $(@D) ] || mkdir -p $(@D)
	@echo "Compiling REAPER code"
	@cd $(BUILD)REAPER/BUILD/; cmake ..; make; cd $(LOCAL)

#########################
# Compute GCIs
#########################


$(REAPER_GCI): $(REAPER)%.csv : $(AUDIO)%.wav
	@[ -d $(@D) ] || mkdir -p $(@D)
	@echo "REAPER GCI compute:    $(notdir $@)"
	@$(REAPER_CMD) -i $< -p $@.tmp -a -m $(min_f0) -x $(max_f0)
	@cat $@.tmp | sed -e '1,7d' | cut -d " " -f 1 > $@
	@rm $@.tmp

$(ESPS_GCI): $(ESPS)%.csv : $(ESPSDATA)%.pm
	@[ -d $(@D) ] || mkdir -p $(@D)
	@echo "ESPS GCI compute:    $(notdir $@)"
	@cat $< | awk --field-searator="\\t" '{print $$2}' > $@

#$(SEDREAMS_GCI): $(SEDREAMS)%.csv : $(AUDIO)%.wav
#	@[ -d $(@D) ] || mkdir -p $(@D)
#	@echo "SEDREAMS GCI compute:    $(notdir $@)"
#	@cd $(LIBOCTAVE); $(OCTAVE) "$(SEDREAMS_CMD)('$<','$@')"; cd $(LOCAL)

$(REF_GCI): $(REFERENCE)%.csv : $(AUDIO)%.wav
	@[ -d $(@D) ] || mkdir -p $(@D)
	@echo "Reference GCI compute:    $(notdir $@)"
	cd $(LIBOCTAVE); $(OCTAVE) "$(REF_CMD)('$<','$@')"; cd $(LOCAL)

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

# TBD: add VQ metrics here


#########################
# BOILERPLATE
#########################

clean:
	rm -rf ./BUILD

show-%:
	@echo "$*= <$($*)>"

showlist-%:
	@echo "$*="
	@$(if $(strip $($*)),for x in $(foreach y,$(subst ",\",$($*)),"$y"); do echo "  $$x"; done)

