function extract_GCI_SEDREAMS( inPath, outPath )

warning off;

% Load required packages    
pkg load tsa;
pkg load signal;

addpath(genpath("./"));
    
% Settings
f0min=50;
f0max=500;
    
% Read in audio file
[x,fs]=wavread( inPath );   

% Extract pitch
[f0,VUV] = pitch_srh( x, fs, f0min, f0max );
medianf0 = median( f0( VUV==1 ) );

% Compute GCIs
gci = gci_sedreams( x, fs, medianf0, 1 );

% Write to text file
dlmwrite( outPath, gci(:) );
