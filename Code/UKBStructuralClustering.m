% Spectral Clustering Analysis
% The code and user manual for Markov Stability is available on https://github.com/michaelschaub/PartitionStability

clear 
while contains(pwd,'UKB_Spectral_Clustering_Project')
    cd ..
end
addpath(genpath('UKB_Spectral_Clustering_Project'))
try
    load('UKBPrepared.mat')
catch
    disp('Preparing Data For Clustering...')
    UKBDataPreparation
end
Extensions = string(fieldnames(FS));
cd 'UKB_Spectral_Clustering_Project\Matfiles'
if ~exist('StabilityClusterResults', 'dir')
    mkdir StabilityClusterResults;
end
cd StabilityClusterResults

for modalities = 1:length(Extensions)
    X=FS.(Extensions(modalities));
    D=DistanceMatrix(X);
    T=10.^linspace(0,2,500);
    K=[5 7 9 11]; %choice of K for graph construction
    for kk = 1:4
        filename = convertStringsToChars(strcat("Freesurfer_UKB_",Extensions(modalities),"_", num2str(K(kk)),"nn graph"));
        if exist(['Stability_' filename '.mat'],'file')>0
            continue
        end
        E=constructNetworkStructure(X, D,'knn',K(kk));
        [S, N, VI, C] = stability(double(E), T,'p','out',filename);
        clearvars S N VI C
        stability_postprocess(['Stability_' filename '.mat'],double(E));
        clearvars E
    end
    clear D X
end