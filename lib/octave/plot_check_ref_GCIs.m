function plot_check_ref_GCIs( EGGDir, refDir )

EGGFiles = dir([EGGDir "/*.wav"]);
N = length(EGGFiles);

pause_time = 1;
stemSize = 0.2;

for n=1:N
    [x,fs]=wavread([EGGDir "/" EGGFiles(n).name]);
    name_split = strsplit(EGGFiles(n).name,".wav");
    ref_name = [name_split{1} ".csv"];

    if ( exist([refDir "/" ref_name]) ) 

        ref_GCIs = dlmread([refDir "/" ref_name]);

        time = ( 1:length(x) ) / fs;
        dEGG = diff(x);
        dEGG = dEGG / max( dEGG );
        plot( time(1:end-1), dEGG )
        hold on
        stem( ref_GCIs, ones(length(ref_GCIs),1)*stemSize, 'r')
        pause(pause_time);

        hold off
    end
end          
