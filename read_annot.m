% xmldoc = xmlread(fullfile('learn-nsrr01-profusion.xml'))
% 
% xmlwrite(xmldoc)

addpath(genpath( '/Volumes/Seagate Expansion Drive/ccshs/polysomnography/annotations-events-profusion/'));

data = xml2struct('ccshs-trec-1800014-profusion.xml') % From http://au.mathworks.com/matlabcentral/fileexchange/28518-xml2struct

%% SleepStages 
% Epoch length
epochLength = data.CMPStudyConfig.EpochLength;

% Sleep stage data
sleepstageS = data.CMPStudyConfig.SleepStages.SleepStage;

%% Extract sleep stage in number
for i=1:length(sleepstageS)
    sleepstage(i,1) = str2num(sleepstageS{1,i}.Text);
    % xlswrite('ccshs_1800005_annot.xlsx',sleepstage(i));
end

%% 
plot(sleepstage)
axis([0 length(sleepstage) 0 6])

%% Save
save('ccshs_1800014_annot','sleepstage','epochLength')