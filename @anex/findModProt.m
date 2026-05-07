function [Bout,iiTraceOut] = findModProt (ee, modality, protocol)
% anex\find_mod_prot harcevests the berabs that have a specified stiulus
% modality and protocol.
%[Bout,iiTraceOut] = find_mod_prot (ee, modality, protocol)
% [Bout,iiTraceOut] = find_mod_prot (ee, 'Optical', 'I')
% Bout=berabrr array
% iiTraceOut=index of the beras that fullfil thee criteria.

L = listBerabr(ee);
iiTraceOut = [];
%criteria
for ii = 1 : numel(L.ABR_SeriesID)
    B = loadBerabr(berabr(ee,L.ABR_SeriesID(ii)));
    switch B.Stim(1).modality
        case  modality
            switch B.Stim(1).protocol
                case protocol
                    iiTraceOut=[iiTraceOut,ii];
                    Bout (numel(iiTraceOut))=B;
            end
    end
end
if isempty(iiTraceOut)
    Bout = [];
end

end


