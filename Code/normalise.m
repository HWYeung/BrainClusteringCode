function [X] = normalise(A,k)
X=(A-nanmean(A,k))./nanstd(A,0,k);
end
