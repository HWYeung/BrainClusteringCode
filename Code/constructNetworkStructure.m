function [E] = constructNetworkStructure(X, D, networkType, para)

% X is the high dimensional matrix (N_dim x N_points)
% D is a matrix with the distances between all points (N_points x N_points)
% networkType is the algorithm which is used to define the network structure
% Available networkType and their parameters are
% 1) 'mst' - Minimum Spanning Tree (MST); 
%   No Parameter
% 2) 'pmst' - Perturbed Minimum Spanning Tree; 
%   para: the number of perturbations
% 3) 'rmst' - Relaxed Minimum Spanning Tree; 
%   para: p in the formular
% 4) 'knn' - k-Nearest Neighbor + MST; 
%   para: number of neighbors
% 5) 'mknn' - Mutual k-Nearest Neighbor + MST; 
%   para: number of neighbors
% 6) 'cknn' - Continous k-Nearest Neighbor; 
%   para: number of neighbors
% 7) 'threshold' - Thresholding the Distance; 
%   para: the threshold
% Zijing Liu Jan 2018

possibleNetworkTypes = {'mst', 'pmst', 'rmst', 'knn', 'mknn', 'cknn', 'epsilon', 'none', 'full','Pearson','unsigned','signed','IBSNetwork'};
if  isempty(find(strcmp(networkType , possibleNetworkTypes))<0)
    error('Unknown networkType : %s\n', networkType);
end


if strcmp(networkType, 'mst') == 1
    E = constructNetworkMST(X, D);
elseif strcmp(networkType, 'pmst') == 1
    E = constructNetworkPMST(X, D, para);
elseif strcmp(networkType, 'rmst')==1
    E = constructNetworkRMST(X,D, para);
elseif strcmp(networkType, 'knn')==1
    E = kNNGraph(D,para);
elseif strcmp(networkType, 'mknn')==1
    E = mkNNGraph(D,para);
elseif strcmp(networkType, 'cknn')==1
    E = ckNNGraph(D,para);
elseif strcmp(networkType, 'epsilon')==1
    E = epsilonGraph(D,para);
elseif strcmp(networkType, 'full')==1
    E = fullGraph(D,para);
elseif strcmp(networkType, 'none')==1
    E = ones(size(D,1));
elseif strcmp(networkType, 'Pearson')==1
    E = Pearson(X,para);
elseif strcmp(networkType, 'unsigned')==1
    E = unsignedCorr(X,para);
elseif strcmp(networkType, 'signed')==1
    E = signedCorr(X,para);
elseif strcmp(networkType, 'IBSNetwork')==1
    E = IBSNetwork(X,para);
end



end




function[E] = constructNetworkPMST(X, D, Niter)

%Perturbed MST
% In several iterations
% The data is perturbed
% A minimum spannig tree is build
%The union of all minimum spanning trees is the final network

N = size(D,1);

%Dimensions of the X matrix
dim = size(X,1);

assert(size(X,2) == N);

%Compute the Euclidean distance matrix
D = squareform(pdist(X'));

%Compute Noise Level
Dtemp = D + eye(N)*max(D(:));
minDtemp = min(Dtemp)/2.0;

%The variance of Gaussian distribution (for each point)
tempsigma = minDtemp.^2/chi2inv(0.9, dim);
tempsigma = sqrt(tempsigma);

%Number of iterations
%Niter = 30000;

E = prim(D);
if isempty (gcp('nocreate'))
    parpool
end
parfor (i =1:Niter)
    Xtemp = X;
    %fprintf('Iter : %d \n', i);
    %Displace the points
    for j = 1:numel(minDtemp)
        noised = minDtemp(j)+1;
        while noised > minDtemp(j)
            noise = randn(dim,1)*tempsigma(j);
            noised = sqrt(sum(noise.^2));
            %fprintf('DN : %f %f \n', noised, minDtemp(j));
        end
        Xtemp(:,j) = Xtemp(:,j) + noise;
    end
    
    %Build the MST
    Dtemp = squareform(pdist(Xtemp'));
    
    %Take the union
    E = E + prim(Dtemp);
    
end

E =  E>0;
end


function [E] = constructNetworkRMST(X,D, p)

%Relaxed Minimum Spanning Tree
%Build a minimum spanning tree from the data
%It is optimal in the sense that the longest link in a path between two nodes is the shortest possible
%If a discounted version of the direct distance is shorter than longest link in the path - connect the two nodes
%The discounting is based on the local neighborhood around the two nodes
%We can use for example half the distance to the nearest neighbors is used.

N = size(D,1);

[~,LLink] = prim(D);

%Find distance to nearest neighbors
Dtemp = D + eye(N)*nanmax(D(:));

mD = nanmin(Dtemp)/p;

%Check condition
mD = repmat(mD, N,1)+repmat(mD',1,N);
E = (D - mD < LLink);
%E = D < 2.*LLink
E = E - diag(diag(E));

end

function [E] = constructNetworkMST(X, D)

E = prim(D);

end

function E = kNNGraph(D,k)

theta = 1e12; % threshold, useless here
n = size(D,1);
sortedD = sort(D);
A = D <= sortedD(k+1,:);
A = (A + A')>0;
A = A - diag(diag(A));
if CheckConnected(A)==1
    E = A;
else
    [Emst,~] = prim(D);
    E = A|Emst;
end
E=E-diag(diag(E));
end

function E = mkNNGraph(D,k)
sortedD = sort(D);
A = D <= sortedD(k+1,:);
A = A - diag(diag(A));

A = A & A';

if CheckConnected(A)==1
    E = A;
else
    [Emst,~] = prim(D);
    E = A|Emst;
end
E=E-diag(diag(E));
end

function E = ckNNGraph(D,param)
k = param(1);
n = size(D,1);
D(1:n+1:end) = 0;
A = zeros(n,n);

dk = zeros(n,1);
for i = 1:n
    [tmp,~] = sort(D(i,:));
    dk(i) = tmp(k+1);
end

Dk = dk * dk';

E = D.^2 < param(2)*Dk;

[Emst,~] = prim(D);
if CheckConnected(E)==1
    E = E;
else
    E = E|Emst;
end
E=E-diag(diag(E));
end

function [E] = epsilonGraph(D,k)
A=(D<k&D>0);
[Emst,~] = prim(D);
if CheckConnected(A)==1
    E = A;
else
    E = A|Emst;
end
E=E-diag(diag(E));
end

function [E] = fullGraph(D,para);
O=sort(D);
E=exp(-D./(2*para^2));
E=E-diag(diag(E));
E(isnan(E)==1)=0;
end

function [E] = Pearson(X,beta);
Y=corr(X');
[M,~]=size(Y);
E=(Y-eye(M)).^beta;
end

function [E] = unsignedCorr(X,beta);
Y=abs(corr(X'));
[M,~]=size(Y);
E=(Y-eye(M)).^beta;
end

function [E] = signedCorr(X,beta);
Y=0.5+0.5*corr(X');
[M,~]=size(Y);
E=(Y-eye(M)).^beta;
end

%function [E] = IBSNetwork(X,[M pvalue]);
%[N,K]=size(X);
%K'=K-M+1
%A_store=cell(K',1);
%C_store=cell(K',1);
%for i=1:K'
 %   S=IBScount(X(:,i:i+M-1));
  %  A=1-(1/(2*M))*S;
   % A_store{i}=A;
    %C_store{i}=eye(N);
%end
%output_A_cell=downsample_slidingwindow( A,C,pvalue,M );

    

function[E,LLink] = prim(D)

% A vector (T) with the shortest distance to all nodes.
% After an addition of a node to the network, the vector is updated
%

LLink = zeros(size(D));
%Number of nodes in the network
N = size(D,1);
assert(size(D,1)==size(D,2));

%Allocate a matrix for the edge list
E = zeros(N);


allidx = [1:N];

%Start with a node
mstidx = [1];

otheridx = setdiff(allidx, mstidx);

T = D(1,otheridx);
P = ones(1, numel(otheridx));



while(numel(T)>0)
	[m, i] = min(T);
	idx = otheridx(i);	

	%Update the adjancency matrix	
	E(idx,P(i)) = 1;
	E(P(i),idx) = 1; 

	%Update the longest links
	%1) indexes of the nodes without the parent
	idxremove = find(mstidx == P(i));
	tempmstidx = mstidx;
	tempmstidx(idxremove) = [];
	
	% 2) update the link to the parent
	LLink(idx,P(i)) = D(idx,P(i));
	LLink(P(i),idx) = D(idx,P(i));
	% 3) find the maximal
	tempLLink = max(LLink(P(i),tempmstidx), D(idx,P(i)));
	LLink(idx, tempmstidx) = tempLLink;
	LLink(tempmstidx, idx) = tempLLink;

	%As the node is added clear his entries		
	P(i) = [];	
	T(i) = [];


	%Add the node to the list 
	mstidx = [mstidx , idx];
	
	%Remove the node from the list of the free nodes
	otheridx(i) = [];
	
	%Updata the distance matrix
	Ttemp = D(idx, otheridx);	
	
	if(numel(T) > 0)
		idxless = find(Ttemp < T);
		T(idxless) = Ttemp(idxless);
		P(idxless) = idx;
	end
end


end
