# Boxplot metrics (separately) as a function of algorithm type
# at the speaker level

# Rscript command line functionality
args <- commandArgs(TRUE)

# Organize input arguments
metricsCSV <- args[1]
RLibrary <- args[2]
output_path <- args[3]

data <- read.table(metricsCSV,header=FALSE,sep=",")
library(reshape2,lib.loc=RLibrary)
library(ggplot2,lib.loc=RLibrary)

metrics <- data[,2:5]
names(metrics) <- c("IR","MR","FAR","IDA")
ID <- as.character(data[,1])
N <- length(ID)
Algorithm <- array("",N)
Dataset <- array("",N)
SpeakerID <- array("",N)
for ( n in seq(N) ) {
    Algorithm[n] <- unlist(strsplit(ID[n],"/"))[1]
    Dataset[n] <- unlist(strsplit(ID[n],"/"))[2]
    SpeakerID[n] <- unlist(strsplit(ID[n],"/"))[3]
}

labels <- cbind(Algorithm,Dataset,SpeakerID)
colnames(labels) <- c("Algorithm","Dataset","SpeakerID")
all_labels <- rbind(labels,labels,labels,labels)
all_metrics <- melt(metrics)
df <- data.frame(all_labels, all_metrics)

pdf(output_path,width=10,height=8)
p1 <- ggplot(df, aes(Algorithm,value,fill=Algorithm)) +
  geom_boxplot() + facet_wrap(~variable,scale="free") +
  ggtitle("GCI metrics at the speaker level")
print(p1)
TMP <- dev.off()
