function StableClusterResult = GetStableCluster(filename,n)
%filename - the postprocessed ones, with _PP.mat at the end
%n - number of clusters  
load(filename);

I = N == n;
vi_smallest = find(VI == min(VI(I&VI>0)));
StableClusterResult = C_new(:,vi_smallest);

end