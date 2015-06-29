function compute_Naylor_GCI_metrics( outPath )

% Make required functions and packages available
addpath(genpath("./"));

% Settings
min_f0 = 50;
max_f0 = 500;
min_glottal_cycle = 1/max_f0;
max_glottal_cycle = 1/min_f0;

    
% Parse path to construct estimate and reference GCI paths
% TBD: this is REALLY ugly and should be handled at the Makefile level    
path_parts = strsplit( outPath, "/" );
nParts = length( path_parts );
ref_parts = path_parts;

for (n=1:length(ref_parts))
    if ( strcmp(ref_parts{n},"Metrics") )
        ref_parts{n} = "Reference";
        break
    end
end

ref_parts(n+1)=[];        
ref_path = strjoin( ref_parts(1:nParts-2), "/" );        

est_parts = path_parts;
est_parts(n) = [];
        
est_path = strjoin( est_parts(1:nParts-2), "/" );        

% Initialize metric quantities
nHit = 0;
nMiss = 0;
nFalse = 0;
nCycles = 0;
highNumCycles = 100000;
estimation_distance = zeros(highNumCycles,1)+NaN;

% Get reference files
ref_files = dir([ ref_path "/*.csv" ] );
nFiles = length(ref_files);

for (n=1:nFiles)
    ref_file = [ref_path "/" ref_files(n).name];
    est_file = [est_path "/" ref_files(n).name];

if (exist( ref_file ) && exist( est_file ) )

    ref_GCIs = dlmread(ref_file);
    est_GCIs = dlmread(est_file);

    for ( m = 2:length(ref_GCIs)-1 )
        % Check for valid larynx cycle
        ref_GCI_dist_forward = ref_GCIs(m+1)-ref_GCIs(m);
        ref_GCI_dist_backward = ref_GCIs(m)-ref_GCIs(m-1);

        if ( ref_GCI_dist_forward > min_glottal_cycle && ...
             ref_GCI_dist_forward < max_glottal_cycle && ...
             ref_GCI_dist_backward > min_glottal_cycle && ...
             ref_GCI_dist_backward < max_glottal_cycle )

            cycle_start = ref_GCIs(m) - ( (ref_GCIs(m) - ref_GCIs(m-1)) / 2 );
            cycle_stop = ref_GCIs(m) + ( (ref_GCIs(m+1) - ref_GCIs(m)) / 2 );

            est_GCIs_in_cycle = est_GCIs( est_GCIs > cycle_start & ...
                                          est_GCIs < cycle_stop );

            n_est_in_cycle = length( est_GCIs_in_cycle );

            % Update counts
            nCycles = nCycles + 1;
            if ( n_est_in_cycle == 1 )
                nHit = nHit +1;
                estimation_distance(nHit) = est_GCIs_in_cycle - ref_GCIs(m);
            elseif ( n_est_in_cycle < 1 )
                nMiss = nMiss + 1;
            else nFalse = nFalse + 1;
            end
        end
    end
end
            
end

% Remove un-filled estimation distance values
estimation_distance = estimation_distance(!isnan(estimation_distance));
            
% Compute final metrics
%    - IR=Identification rate, MR=Miss rate, FAR=False alarm rate,
%      IDA=Identification accuracy
IR = nHit / nCycles;
MR = nMiss / nCycles;
FAR = nFalse / nCycles;
IDA = std( estimation_distance );

% Write headers and metrics to text file
file_header = cell(1,4);
file_header{1} = "IR";
file_header{2} = "MR";
file_header{3} = "FAR";
file_header{4} = "IDA";

dlmwrite( outPath, strjoin(file_header,","), "delimiter", "" );
dlmwrite( outPath, [ IR,MR,FAR,IDA ], "delimiter", ",", "-append" );


path_parts(nParts) = "estimation_accuracy.csv";

outPath_accuracy = strjoin( path_parts, "/" );
dlmwrite( outPath_accuracy, estimation_distance(:) );
