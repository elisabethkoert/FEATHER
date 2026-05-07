function B = stim(B)
% berabr\stim - extracts stimulus properties from the berabr
% The hardware names are hardcoded.

S_field_names = {'exp_li','stimulusHardware','anuTag','modality','mode','unit','duration','intensity','repRate','protocol'} ;
temp_c = cell(length(S_field_names),1);
S = cell2struct(temp_c,S_field_names);

bera_raw.IsData = B.R;%I have to do it foro consistency with bera code..
%identify protocol
if~isempty(fields(bera_raw))
    switch strtrim(bera_raw.IsData(1).Speaker )%I can use IsData(1) hardcoded, as it is the same for all the consequent recordings
        case strtrim('avisoft           ')
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).anuTag = 0; %0 is acoustic according to ANUs tagging system
                S(ii).modality = 'Acoustic';
                S(ii).stimulusHardware=bera_raw.IsData(1).Speaker;
                S(ii).mode =bera_raw.IsData(1).BERAStimMode;
                S(ii).unit = 'dB SPL';
                %perhaps this can be improved, it seems like a redundant
                %hardocoding
                if isfield(bera_raw.IsData(1), 'ClickPulsTime')==1
                    S(ii).duration=bera_raw.IsData(1).ClickPulsTime;
                else
                    S(ii).duration=1/bera_raw.IsData(1).StimRepeatPerSec*10^3;
                end
                S(ii).intensity =bera_raw.IsData(ii).dbSPL;
                S(ii).repRate=bera_raw.IsData(ii).StimRepeatPerSec;
            end
            [temp_protocol ] = local_IDR(S);
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).protocol = temp_protocol;
            end
        case strtrim('Laser ObisTTL     ') %orange laser
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).anuTag = 1; %1 is optical according to ANUs tagging system
                S(ii).modality='Optical';
                S(ii).stimulusHardware=bera_raw.IsData(1).Speaker;
                S(ii).mode=bera_raw.IsData(1).BERAStimMode;
                S(ii).unit='mW';
                S(ii).duration=bera_raw.IsData(ii).isIntensTimeValue1;
                S(ii).intensity=bera_raw.IsData(ii).Intens1;
                S(ii).repRate=bera_raw.IsData(ii).StimRepeatPerSec;
            end
            [temp_protocol ] = local_IDR(S);
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).protocol = temp_protocol;
            end
        case strtrim('uLED Array        ')%for uLED and waveguides, careful with that one!
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).anuTag = 1; %1 is optical according to ANUs tagging system
                S(ii).modality='Optical';
                S(ii).stimulusHardware=bera_raw.IsData(1).Speaker;
                S(ii).mode=bera_raw.IsData(1).BERAStimMode;
                S(ii).unit='mW';
                S(ii).duration=bera_raw.IsData(ii).isIntensTimeValue1;
                S(ii).intensity=bera_raw.IsData(ii).Intens1;
                S(ii).repRate=bera_raw.IsData(ii).StimRepeatPerSec;
            end
            [temp_protocol ] = local_IDR(S);
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).protocol = temp_protocol;
            end
        case strtrim('Laser TTL AOTF 473')
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).anuTag = 1; %1 is optical according to ANUs tagging system
                S(ii).modality='Optical';
                S(ii).stimulusHardware=bera_raw.IsData(1).Speaker;
                S(ii).mode=bera_raw.IsData(1).BERAStimMode;
                S(ii).unit='mW';
                S(ii).duration=bera_raw.IsData(ii).isIntensTimeValue1;
                S(ii).intensity=bera_raw.IsData(ii).Intens1;
                S(ii).repRate=bera_raw.IsData(ii).StimRepeatPerSec;
            end
            [temp_protocol ] = local_IDR(S);
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).protocol = temp_protocol;
            end
        case strtrim('Laser Oxxius      ')
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).anuTag = 1; %1 is optical according to ANUs tagging system
                S(ii).modality='Optical';
                S(ii).stimulusHardware=bera_raw.IsData(1).Speaker;
                S(ii).mode=bera_raw.IsData(1).BERAStimMode;
                S(ii).unit='mW';
                S(ii).duration=bera_raw.IsData(ii).isIntensTimeValue1;
                S(ii).intensity=bera_raw.IsData(ii).Intens1;
                S(ii).repRate=bera_raw.IsData(ii).StimRepeatPerSec;
            end
            [temp_protocol ] = local_IDR(S);
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).protocol = temp_protocol;
            end
        case strtrim( 'Laser RedL660P  ')
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).anuTag = 1; %1 is optical according to ANUs tagging system
                S(ii).modality='Optical';
                S(ii).stimulusHardware=bera_raw.IsData(1).Speaker;
                S(ii).mode=bera_raw.IsData(1).BERAStimMode;
                S(ii).unit='mW';
                S(ii).duration=bera_raw.IsData(ii).isIntensTimeValue1;
                S(ii).intensity=bera_raw.IsData(ii).Intens1;
                S(ii).repRate=bera_raw.IsData(ii).StimRepeatPerSec;
            end
            [temp_protocol ] = local_IDR(S);
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).protocol = temp_protocol;
            end


            %         case strtrim('Laser OxxiusMPA   ') %green laser
            %             for ii =  1 :  numel(bera_raw.IsData)
            %                 S(ii).anuTag = 1; %1 is optical according to ANUs tagging system
            %                 S(ii).modality='Optical';
            %                 S(ii).stimulusHardware=bera_raw.IsData(1).Speaker;
            %                 S(ii).mode=bera_raw.IsData(1).BERAStimMode;
            %                 S(ii).unit='mW';
            %                 S(ii).duration=bera_raw.IsData(ii).isIntensTimeValue1;
            %                 S(ii).intensity=bera_raw.IsData(ii).Intens1;
            %                 S(ii).repRate=bera_raw.IsData(ii).StimRepeatPerSec;
            %             end
            %             [temp_protocol ] = local_IDR(S);
            %             for ii =  1 :  numel(bera_raw.IsData)
            %                 S(ii).protocol = temp_protocol;
            %             end
        case strtrim('LaserOxxiusMPA542') %green laser, after the computer upgrade
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).anuTag = 1; %1 is optical according to ANUs tagging system
                S(ii).modality='Optical';
                S(ii).stimulusHardware=bera_raw.IsData(1).Speaker;
                S(ii).mode=bera_raw.IsData(1).BERAStimMode;
                S(ii).unit='mW';
                S(ii).duration=bera_raw.IsData(ii).isIntensTimeValue1;
                S(ii).intensity=bera_raw.IsData(ii).Intens1;
                S(ii).repRate=bera_raw.IsData(ii).StimRepeatPerSec;
            end
            [temp_protocol ] = local_IDR(S);
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).protocol = temp_protocol;
            end

        case strtrim('Laser OxxiusAnalog') %blue laser,DS used by AV for FYTC
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).anuTag = 1; %1 is optical according to ANUs tagging system
                S(ii).modality='Optical';
                S(ii).stimulusHardware=bera_raw.IsData(1).Speaker;
                S(ii).mode=bera_raw.IsData(1).BERAStimMode;
                S(ii).unit='mW';
                S(ii).duration=bera_raw.IsData(ii).isIntensTimeValue1;
                S(ii).intensity=bera_raw.IsData(ii).Intens1;
                S(ii).repRate=bera_raw.IsData(ii).StimRepeatPerSec;
            end
            [temp_protocol ] = local_IDR(S);
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).protocol = temp_protocol;
            end






        case  strtrim('Laser A   AOTF 473')
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).anuTag = 1; %1 is optical according to ANUs tagging system
                S(ii).modality='Optical';
                S(ii).stimulusHardware=bera_raw.IsData(1).Speaker;
                S(ii).mode=bera_raw.IsData(1).BERAStimMode;
                S(ii).unit='mW';
                S(ii).duration=bera_raw.IsData(ii).isIntensTimeValue1;
                S(ii).intensity=bera_raw.IsData(ii).Intens1;
                S(ii).repRate=bera_raw.IsData(ii).StimRepeatPerSec;
            end
            [temp_protocol ] = local_IDR(S);
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).protocol = temp_protocol;
            end
        case strtrim('electric_placeholder')
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).anuTag = 2; %1 is electric according to ANUs tagging system
                S(ii).modality='Electric';
                S(ii).mode=bera_raw.IsData(1).BERAStimMode;
                S(ii).unit='mV';
                S(ii).duration=bera_raw.IsData(ii).isIntensTimeValue1;
                S(ii).intensity=bera_raw.IsData(ii).isIntensArrayDevBoard;
                S(ii).repRate=bera_raw.IsData(ii).StimRepeatPerSec;
            end
            [temp_protocol ] = local_IDR(S);
            for ii =  1 :  numel(bera_raw.IsData)
                S(ii).protocol = temp_protocol;
            end
    end


end
B.Stim = S;
%
end



function [out] = local_IDR(S)
%check if the Intensity, the duration or the rep rate changes
all_I = unique(horzcat(S(:).intensity));
all_D = unique(horzcat(S(:).duration));
all_R = unique(horzcat(S(:).repRate));
if numel(all_I)>1 && numel(all_D)==1 && numel(all_R)==1
    out='I';
elseif  numel(all_I)==1 && numel(all_D)>1 && numel(all_R)==1
    out='D';
elseif  numel(all_I)==1 && numel(all_D)==1 && numel(all_R)>1
    out='R';
else
    out=' ';
end
end

