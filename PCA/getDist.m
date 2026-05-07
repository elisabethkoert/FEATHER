function [dist_mat]=getDist(array_PCA, weighing_bool,method)
%% This is a function to calculate the euclidian ditance between the means of two stimulus representations in the PC space (RDM)
% Input: 
% array:PCA this is a (D*T)xS Cell array, S is the number of sounds that
% should be compared, D is the number of Principal components analyzed, T
% is the number of time bins
% wegihing bool:double, either 1 or 0. switch to set wether the arrays
% should be weighed by the std before caclulating the distance or not (NOT necessary for mahalanobis).
% Output: 
% dist_mat: This is the SxS double matrix (containing the euclidian distance between the stimulus representations)
n=numel(array_PCA);
PCA_means=cellfun(@(x) mean(x,1)', array_PCA,'UniformOutput',false);
PCA_means=(cell2mat(PCA_means))';
if weighing_bool==1
    PCA_std=cellfun(@(x) std(x)', array_PCA,'UniformOutput',false);
    PCA_std=(cell2mat(PCA_std))';
    PCA_means_weighed=PCA_means/PCA_std;
    euc_weighed=pdist(PCA_means_weighed);
    dist_mat=squareform(euc_weighed);
else
if strcmp(method,'euclidean')
    euc=pdist(PCA_means);
    dist_mat=squareform(euc);
elseif strcmp(method,'mahalanobis')
    for i=1:n
        for j=1:n
            cov_mat=cov(array_PCA{i});
          try
           dist_mat(i,j)=pdist2(PCA_means(j,:),PCA_means(i,:),'mahalanobis',cov_mat);
          catch
           dist_mat(i,j)=NaN;
          end
        end
    end
end
end
end
