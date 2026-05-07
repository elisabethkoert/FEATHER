function [dist_mat_dPrime]=getDist_as_dPrime(array_PCA_reps,array_PCA_reps_noise,method,calc_dPrime)
%% This is a function to calculate the euclidian ditance between the means of two stimulus representations in the PC space (RDM)
% Input: 
% array_PCA_reps_reps this is a (D*T*R)xS Cell array, S is the number of sounds that
% should be compared, D is the number of Principal components analyzed, T
% is the number of time bins nad R is the number of repeption that the
% stimulus was presented 
% wegihing bool:double, either 1 or 0. switch to set wether the arrays
% should be weighed by the std before caclulating the distance or not (NOT necessary for mahalanobis).
% Output: 
% dist_mat: This is the SxS double matrix (containing the euclidian distance between the stimulus representations)
repetitions=[1:1:size(array_PCA_reps,2)];
n=numel(array_PCA_reps{1});
for rep_ix=1:max(repetitions)
    PCA_means{rep_ix}=cellfun(@(x) mean(x,1)', array_PCA_reps{1,rep_ix},'UniformOutput',false);
    PCA_means{rep_ix}=(cell2mat(PCA_means{rep_ix}))';
end
clear('rep_ix')
for rep_ix=1:max(repetitions)
    PCA_means_noise{rep_ix}=cellfun(@(x) mean(x,1)', array_PCA_reps_noise{1,rep_ix},'UniformOutput',false);
    PCA_means_noise{rep_ix}=(cell2mat(PCA_means_noise{rep_ix}))';
end
clear('rep_ix')
shuffle_ix=nchoosek(repetitions,2);
shuffle_ix=[[repetitions',repetitions'];shuffle_ix];
if strcmp(method,'euclidean')
    for i=1:n
        for j=1:n
            for rep_ix=1:size(shuffle_ix,1)
               dist_mat{rep_ix}(i,j)=pdist2(PCA_means{shuffle_ix(rep_ix,1)}(i,:),PCA_means{shuffle_ix(rep_ix,2)}(j,:));
               dist_mat_noise{rep_ix}(i,j)=pdist2(PCA_means{shuffle_ix(rep_ix,1)}(i,:),PCA_means{shuffle_ix(rep_ix,2)}(i,:));  
        end
        end
    end
elseif strcmp(method,'mahalanobis')
    for i=1:n
        for j=1:n
            for rep_ix=1:size(shuffle_ix,1)
                cov_mat=cov(array_PCA_reps{shuffle_ix(rep_ix,1)}{j});
              try
               dist_mat{rep_ix}(i,j)=pdist2(PCA_means{shuffle_ix(rep_ix,1)}(i,:),PCA_means{shuffle_ix(rep_ix,2)}(j,:),'mahalanobis',cov_mat);
              catch
               dist_mat{rep_ix}(i,j)=NaN;
              end
        end
        end
    end
for i=1:n
        for j=1:n
            for rep_ix=1:size(shuffle_ix,1)
                cov_mat=cov(array_PCA_reps{shuffle_ix(rep_ix,1)}{j});
              try
               dist_mat_noise{rep_ix}(i,j)=pdist2(PCA_means{shuffle_ix(rep_ix,1)}(j,:),PCA_means_noise{shuffle_ix(rep_ix,2)}(j,:),'mahalanobis',cov_mat);
              catch
               dist_mat_noise{rep_ix}(i,j)=NaN;
              end
        end
        end
end
elseif strcmp(method,'correlation')
    for i=1:n
        for j=1:n
            for rep_ix=1:size(shuffle_ix,1)   
               array1=array_PCA_reps{1,shuffle_ix(rep_ix,1)}{1,i}';
               array2=array_PCA_reps{1,shuffle_ix(rep_ix,2)}{1,j}';
               dist_mat{rep_ix}(i,j)=1-corr(array1(:),array2(:));               
        end
        end
    end
for i=1:n
        for j=1:n
            for rep_ix=1:size(shuffle_ix,1)
                array1=array_PCA_reps_noise{1,shuffle_ix(rep_ix,1)}{:,i}';
               array2=array_PCA_reps_noise{1,shuffle_ix(rep_ix,2)}{:,j}';
               dist_mat_noise{rep_ix}(i,j)=1-corr(array1(:),array2(:));  
        end
        end
    end
end
IC=[];
for i=1:n
    for j=1:n
        if calc_dPrime==0
            Dprime(i,j)=mean(cellfun(@(x) x(i,j),dist_mat));
        else
            P=cellfun(@(x) x(i,j),dist_mat);
            N=cellfun(@(x) x(i,j),dist_mat_noise);
            if any(isnan(P)) || any(isnan(N))
                Dprime(i,j)=NaN
            else
                [ROCmat, AUC, Dprime(i,j), SE] = ROCAna_03([],N, P);
            end
        end
    end
end
dist_mat_dPrime=Dprime;
end

