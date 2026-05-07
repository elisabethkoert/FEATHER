function [is_array_smooth]=get_smooth(is_array_TwoTone,binsize,kernel_width)
%% This is a function to kernel smooth the given array in is_array_TwoTone
% Input: 
% is_array_TwoTone: PSTH (binned spike counts) over units and averages,
% dimenesions: MxRxT (UnitsxRepetitionsxTimes instances)
% binsize: binsize in ms used for PSTH construction
% kernel width: width of the applied gaussian kernel in ms
%Output: 
% is_array_smooth: smoothed array following the same dimensions as the
% input array
is_array_smooth=zeros(size(is_array_TwoTone));
[NElecs,NTrials,~]=size(is_array_TwoTone);
kernel=gausswin(kernel_width*binsize,2.5);
for i=1:NElecs
    for j=1:NTrials
        is_array_smooth(i,j,:)=...
            conv(permute(is_array_TwoTone(i,j,:),[1 3 2]),kernel,'same');
    end
end
end
      
