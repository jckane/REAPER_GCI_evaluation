function extract_reference_GCIs( audioPath, outPath )

warning off;
    
% Make required functions and packages available
addpath(genpath("./"));
pkg load tsa;
pkg load signal;

% Construct EGG path from audioPath
% TBD: this is REALLY ugly and should be handled at the Makefile level
EGG_parts = strsplit( audioPath,"/" );
for (n=1:length(EGG_parts))
    if ( strcmp(EGG_parts{n},"audio") )
        break
    end
end
            
EGG_parts{n} = "EGG";
EGGPath = strjoin(EGG_parts,"/");

% Read in audio file and EGG file
[x,fs]=wavread( audioPath );
[x_egg,fs_egg]=wavread( EGGPath );
dEGG = diff(x_egg);
dEGG = dEGG / max( dEGG ); % Amplitude normalise

nSamples = min([length(x),length(dEGG)]);
x = x(1:nSamples);
dEGG = dEGG(1:nSamples);

% Settings
LPres_fDuration = round(25/1000*fs);
LPres_fPeriod = round(5/1000*fs);
LPres_order = round(fs/1000) + 2;
xCorrMaxLag = round( 0.05 * fs );
dEGGthresh = 0.05;
max_f0 = 500;

% Select segment for cross-correlation based delay compensation
if (length(x) > fs+1000 )
    xCorrSegment = 1:(fs+1000);
else xCorrSegment = 1:length(x);
end
dEGG_seg = dEGG(xCorrSegment);
x = x(xCorrSegment);

% Compute LPC residual for audio segment
res = lpcresidual( x, fs, LPres_fDuration, LPres_fPeriod, LPres_order );

% User cross correlation to determine 'acoustic' delay between microphone
% and EGG
[resEGGxCorr,lags] = xcorr(res,dEGG_seg,xCorrMaxLag,'coeff');
[TMP,xCorrMaxIdx] = max( resEGGxCorr );
maxLags = lags(xCorrMaxIdx);

if ( maxLags < 0 )
    dEGG = dEGG(abs(maxLags):end);
elseif ( maxLags > 0 )
    dEGG = [zeros(maxLags,1); dEGG];
end

% Derive reference GCIs from dEGG through magnitude threshold
%[peak_amp,peak_idx] = findpeaks( dEGG, "MinPeakDistance", (1/max_f0)*fs );
[peak_amp,peak_idx] = findpeaks( dEGG ); 
GCI = peak_idx( peak_amp > dEGGthresh );
GCI = GCI / fs;

% TBD: determine whether post-processing is required!


% Write to text file
dlmwrite( outPath, GCI(:) );




