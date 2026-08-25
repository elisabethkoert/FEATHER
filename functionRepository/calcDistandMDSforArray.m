function [dist_mat, MDS_out]=calcDistandMDSforArray(d_prime_array,channel_groups,SpikeRateLevels, plotBool)
% calcDistandMDSforArray measures how dissimilar a set of response profiles are
% and projects them into two dimensions
% Core of the representational similarity analysis: every column of the input
% is the response of the recorded electrodes to one stimulus condition, and the
% dissimilarity of two conditions is 1 minus the Pearson correlation between
% their profiles. When asked to plot, the dissimilarities are projected into
% two dimensions by classical multidimensional scaling and drawn into the
% current axes, so that the distance between two markers reflects how
% differently the two conditions were represented.
%
% input:
%   d_prime_array (e x c double) one column per condition, one row per
%       recording electrode. Despite the name any response measure can be
%       passed; the figure scripts hand over evoked spike rates.
%   channel_groups (1xc double) the stimulus each column belongs to, e.g. the
%       emitter or tone frequency. Only used for the plot, where it sets the
%       marker colour and connects the conditions of one stimulus.
%   SpikeRateLevels (1xk double) the activity levels the conditions of a
%       stimulus were read out at. Only used for the plot, where it sets how
%       many grey levels the markers are shaded with.
%   plotBool (logical/double) 1 draws the projection into the current axes,
%       0 only computes the dissimilarities
% output:
%   dist_mat  the pairwise dissimilarities. Note that the shape depends on
%       plotBool: with plotBool 0 it is the condensed vector returned by pdist,
%       with plotBool 1 it is the square matrix the projection was computed
%       from.
%   MDS_out (c x 2 double) coordinates of the projection, empty when plotBool
%       is 0 because no projection is computed then.
%
% assumptions:
%   Correlation distance ignores the overall scale of a profile, so two
%   conditions with the same pattern but different overall activity count as
%   identical. This is intended: the figure scripts match activity beforehand.
%   The axis limits are set on every call, also when nothing is drawn.
%% first calculate distance correctly
clear('dist_mat')
% An alternative that was tried and not used: binarising the profiles at
% d' = 1 would reduce every electrode to active or inactive, so that the
% dissimilarity depends on which electrodes respond and not on how strongly.
MDS_out = [];
[dist_mat]=pdist(d_prime_array','correlation');%
if plotBool==1
    % drop condition pairs whose correlation was undefined, then turn the
    % condensed distance vector into the square matrix cmdscale expects
    nan_rows = isnan(dist_mat);
    dist_mat(nan_rows) = [];
    dist_mat=squareform(dist_mat);
    [MDS_out,eigenvalues]=cmdscale(dist_mat,2);
    pltsets=styleParams();
    hold on
    plot_channels=unique(channel_groups);
    % markers are filled from white to black with rising activity level, so
    % that the path of one stimulus through the projection stays readable
    N_grey_lvls = numel(SpikeRateLevels);
    gray_vals = linspace(1, 0, N_grey_lvls)';
    grayscale_dP = repmat(gray_vals, 1, 3);
    for channel_ix=1:numel(plot_channels)
        cur_channel_ix=find(channel_groups==plot_channels(channel_ix));
         plot(MDS_out(cur_channel_ix,1),MDS_out(cur_channel_ix,2),'LineStyle','--','LineWidth',pltsets.LINEWIDTH,'Color',pltsets.colorcode10(channel_ix,:));
        for SR_ix=1:numel(cur_channel_ix)
            scatter(MDS_out(cur_channel_ix(SR_ix),1),MDS_out(cur_channel_ix(SR_ix),2),20,'filled','MarkerEdgeColor',pltsets.colorcode10(channel_ix,:),'MarkerFaceColor',grayscale_dP(SR_ix,:),'LineWidth', pltsets.LINEWIDTH);
        end
    end
end
xlim([-10 10])
ylim([-5 5])
hold off
% disp(eigenvalues)

