function [coeff, score, latent, signal_latent]=getManifold(array_all, array_reps,plot_bool)
%% This is a function to get the signal manifold for a specific dataset. 
% It applys PCA on an array containing the the binned spikecount for a
% given dataset. It gives back how many of the prinincial components
% actually explain signal variance menaing they explain covariance between
% repeated trials of the same stimulus. The subspace defined by these
% prinincipal components is called the signal manifold. 
% Input: 
% array_all: MXT double array, M is the nuimber of Multi-Units (32 in our
% setup, T is the number of time bins which is definedwhen extracting the
% Spikecount from the Spikelist.
% array_reps s the same aray divided up by Repititiopns into MxRXT with R
% being the Number of repetitions. These are used for the analysis of the
% signal manifold. 
%plot_bool: 0 or 1 dpending on if a plot of the explained variance is
%wanted as feedback
% Output: 
% coeff: double array containing the PC. 
% score
% latent: double array with the variance explained by each PC in coeff. 
% signal_latent: double array with the signal variance by each PC in coeff. 
% figure: 1x3 Figure giving an overview over the explained signal and total
% variance. 
is_array_reps=array_reps;
 % Array needs to be nirrored to apply pca correctly
array_all=squeeze(array_all);
% array_all=squeeze(sum(is_array_reps(:,3:3:end,:),2));% for test NA 30.12.2024
array_all=array_all';
array_centered=array_all-mean(array_all,2); % centering of the array 
[coeff, score, latent] = pca(array_centered);
total_var=sum(latent);
is_explained_plot=latent./total_var;
is_explained_plot=cumsum(is_explained_plot);
%% Here the test groups are defined
intermediate_test1=is_array_reps(:,1:2:end,:);
intermediate_test2=is_array_reps(:,2:2:end,:);
is_test1=[];
is_test2=[];
%% Here different options for the creation of the test arrays wre explored
% State 02.02.25: the mean for the slected repetitions was taken
%% All reps Concatenated
% for ll=1:size(intermediate_test1,2)
%     is_test1=cat(2,is_test1,squeeze(intermediate_test1(:,ll,:)));
%     is_test2=cat(2,is_test2,squeeze(intermediate_test2(:,ll,:)));
% end
%% Sum of all reps
% is_test1=squeeze(sum(intermediate_test1,2));
% is_test2=squeeze(sum(intermediate_test2,2));
%% Mean of the sekected reos
is_test1=squeeze(mean(intermediate_test1,2));
is_test2=squeeze(mean(intermediate_test2,2));
% is_test1=squeeze(intermediate_test1(:,1,:));
% is_test2=squeeze(intermediate_test2(:,2,:));
% mirroring for applying on PC
is_test1=is_test1';
is_test2=is_test2';
for jj=1:size(coeff,2) % loops through the principal components to get the explained variance for each additional PC
    selected_coeff=coeff(:,1:jj);
    test1_PC=(is_test1-mean(is_test1,2))*coeff(:,1:jj);
    test1_recon=(test1_PC* selected_coeff')+mean(is_test1,2); % Test 1 reconstruction
    test2_recon=(test1_PC*selected_coeff')+mean(is_test2,2);% Test 2 is the same way as Test 1 + the mean of test 2 to get the explaine signal variance
    cov_test1=cov(test1_recon(:),is_test1(:));
    cov_test2=cov(test2_recon(:),is_test2(:));
    total_var(jj)=cov_test1(1,2)/sqrt((var(is_test1(:))*var(test1_recon(:))));
    signal_var(jj)=cov_test2(1,2)/sqrt((var(is_test2(:))*var(test2_recon(:))));
end
if plot_bool==1
    manifold_fig=figure();
    % subplot(3,1,1)
    % plot(is_explained_plot,'LineWidth',3);
    % title('Variance Explained by PC')
    % xlabel('No. of PC')
    % ylim([0 1])
    % xlim([1 32])
    % subplot(3,1,2)
    % plot(total_var,'LineWidth',3)
    % title('Total Variance Explained')
    % xlabel('No. of PC')
    % ylim([0 1])
    % xlim([1 32])
    % subplot(3,1,3)
    plot(signal_var./max(signal_var),'LineWidth',3,'Color',  [52 244 10]/255);
    % plot(signal_var./max(signal_var),'LineWidth',3,'Color',  [1, 0, 1]);
    title('Signal Variance Explained')
    xlabel('No. of PC')
    ylim([0 1])
    xlim([1 32])
end
signal_latent=signal_var;
end