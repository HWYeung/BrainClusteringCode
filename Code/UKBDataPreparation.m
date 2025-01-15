%% Data Preparation
clear
addpath(genpath('UKB_Spectral_Clustering_Project'))
FSOriginal=readtable("UKBFreeSurfer.csv");
MDDDiagnosis=readtable("MHQ_Derived_MDD.csv");
Demographics=readtable("UKBDemographics.csv");
UKBCognitive = readtable("UKB_CognitiveTasks.csv");
CranialVolume=readtable("UKBICV.csv");
T = innerjoin(Demographics,CranialVolume,'LeftKeys','f_eid','RightKeys','id_4844');
T = innerjoin(T,FSOriginal,'Keys','f_eid');
T = innerjoin(T,UKBCognitive,'LeftKeys','f_eid','RightKeys','id_4844');
T = innerjoin(T,MDDDiagnosis,'LeftKeys','f_eid','RightKeys','id_4844');
Covariates = T(:,3:8).Variables;
FreeSurfer=T(:,9:233).Variables;
CognitiveTasks = T(:,234:237).Variables;
MDDstatus=T(:,238).Variables;
clearvars -except Covariates FreeSurfer CognitiveTasks MDDstatus

%Remove Outliers
[SAsum,~] = find(abs(normalise(sum(FreeSurfer(:,69:136),2),1))>3);
[Volsum,~] = find(abs(normalise(sum(FreeSurfer(:,137:204),2),1))>3);
[HeadSize,~]=find(abs(normalise(Covariates(:,6),1))>3);
[Headmotion,~]=find(abs(normalise(Covariates(:,1:3),1))>=4);
Remove = unique([SAsum;Volsum;HeadSize;Headmotion]);
Covariates(Remove,:) = [];
FreeSurfer(Remove,:) = [];
CognitiveTasks(Remove,:) = [];
MDDstatus(Remove,:) = [];

%Transform Cognitive Tasks' Scores and Compute G-factor 

CognitiveTasks(:,2) = log(CognitiveTasks(:,2));
CognitiveTasks(:,3) = log(CognitiveTasks(:,3)+1);
I=sum((isnan(CognitiveTasks)),2)>0;
[lambda,psi,T,stats,g_f] = factoran(CognitiveTasks(~I,:),1,'scores','regression');
CognitiveTasks(:,5) = nan;
CognitiveTasks(~I,5) = g_f;


NewX1=zeros(size(FreeSurfer));
for i=1:225
    Mdl=fitglm(Covariates(:,4:end),FreeSurfer(:,i));
    NewX1(:,i)=table2array(Mdl.Residuals(:,"Raw"));
end

X=normalise(NewX1,1);
FS.CorticalThickness = X(:,1:68);
FS.CorticalSurfaceArea = X(:,69:136);
FS.CorticalVolume = X(:,137:204);
FS.SubcorticalVolume = X(:,205:225);
clearvars -except FS Covariates CognitiveTasks MDDstatus
save(fullfile('Matfiles/UKBPrepared.mat'),'FS','CognitiveTasks','Covariates','MDDstatus');