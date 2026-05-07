function [yMean,yCI95]=get95CI(y)
    %get95CI little helper to get the mean and 95% confidence interval
    %input:
    %   y (array nxm) is Dependent Variable/  Experimental Data where each
    %   collumn gets treated individually as one set of data; so single
    %   data needed in format nx1
    % output:
    %   ymean

%     % standard calculation
% %     y(isnan(y))=[];
%     N = length(y);                                      % Number of eExperimentsn In Data Set
%     yMean = mean(y);                                    % Mean Of All Experiments At Each Value Of ‘x’
%     ySEM = std(y)/sqrt(N);                              % Compute ‘Standard Error Of The Mean’ Of All Experiments At Each Value Of ‘x’
%     CI95 = tinv([0.025 0.975], N-1);                    % Calculate 95% Probability Intervals Of t-Distribution
%     yCI95 = bsxfun(@times, ySEM, CI95(:));              % Calculate 95% Confidence Intervals Of All Experiments At Each Value Of ‘x’
    %% bootstrapping method
    [n_rows,n_col]=size(y);
    % if a single data set accidently went in with wrong size turn it
    % around
    if n_rows==1 && n_col ~=1
        y=y'; 
    end
    yMean=[];
    yCI95=[];
    for ii=1:n_col
        cur_y=y(:,ii);
        cur_y(isnan(cur_y))=[];
        cur_y(isinf(cur_y))=[];
        n = length(cur_y);
        num_boot = 1000;
        boot_means = zeros(num_boot, 1);
        
        for i = 1:num_boot
            boot_sample = datasample(cur_y, n, 'Replace', true);
            boot_means(i) = mean(boot_sample);
        end
        
        cur_yCI95 = prctile(boot_means, [2.5 97.5]); % 95% CI
        cur_yMean=mean(cur_y);
        % since later the CI is plotted via errorbar we do not want the
        % absolute values but +- from themean
        cur_yCI95=cur_yCI95-cur_yMean;
        % put in overall array
        yMean=[yMean;cur_yMean];
        yCI95=[yCI95;cur_yCI95];
    end
    
    
end