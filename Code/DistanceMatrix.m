function [D] = DistanceMatrix(A)

B=sum(A.^2,2);
D = real(sqrt(B+B'-2*(A*A')));
end

