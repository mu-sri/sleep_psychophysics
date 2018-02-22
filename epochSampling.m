%% Function: Sample epochs uniformly across all sleep stages
% Input: whichData // which dataset to be used ([1,5,7,13,14] for now)
% Output : epochID // randomised order of epoch IDs


function epochID = epochSampling(whichData)
% Make a function after tested

%% Check if data set exists
% Use ccshs1800001 as default (avoid error)
addpath(genpath('/Users/sleeping/Downloads/sleep_psych_data'));
validData = [1,5,7,13,14]; % Valid datasets
if ~ismember(whichData,validData)
    whichData = 1; % Default case or display error?
    % error('Dataset is invalid...input: 1,5,7,13, or 14
    
end
%% Load annotation file of the whichData
% After reading the annotation file from xml using read_annot.m
% **** If not in the same folger
% addpath(genpath('/Users/sleeping/Documents/MATLAB/ccshs_data'))
annotFile = strcat('ccshs_1800',num2str(whichData,'%03d'),'_annot.mat');

annotation = load(annotFile);
label = annotation.sleepstage;

%% Remove initial W stage from randomisation and sampling
% Marking the end of W stage
endW = [334,380,391,375,174];
endS = [1374,1442,1442,1531,1492]; % Remove awake period at the end + no-recording epochs

endID = find(whichData==validData);

selectID = [endW(endID)+1:endS(endID)-1];
selectLabel = label(selectID);

%% Counting number of stages
% Proportion of each sleep stage (0 - wake, 1-4 NREM, 5 - REM)
stgNum = size(unique(label));
stgLab = {'W','N1','N2','N3','R'};

% Record number of epochs in each stage and the ID of the epoch
w = 0; n1 = 0; n2 = 0; n3 = 0; r = 0;
for n = 1:length(selectLabel)
    switch selectLabel(n)
        case 0 % Wake
            w=w+1;
            stgID.allID.W(w) = n;
        case 1 % N1
            n1=n1+1;
            stgID.allID.N1(n1) = n;
        case 2 % N2
            n2=n2+1;
            stgID.allID.N2(n2) = n;
        case 3 % N3
            n3=n3+1;
            stgID.allID.N3(n3) = n;
        case 5 % REM
            r=r+1;
            stgID.allID.R(r) = n;
    end
end

% Number of epoch in each stage
stgID.stgN = [w, n1, n2, n3, r];
clear w n1 n2 n3 r


% Minimum samples
stgID.Nmin = min(stgID.stgN);

%% Randomise order of each stage
stgID.useID =[];

for m=1:length(stgID.stgN)
    randID = randperm(stgID.stgN(m),stgID.Nmin); % Random permutation - index of one stage
    allID = stgID.allID.(char(stgLab(m))); % All epoch id of that stage
    useID = allID(randID);  % Take randomised epoch id
    stgID.useID.(char(stgLab(m))) = useID;
end

% Concatenate all indices
temp=[stgID.useID.W,stgID.useID.N1,stgID.useID.N2,stgID.useID.N3,stgID.useID.R];

% Randomised order of indices
randorder=randperm(length(temp));
randomindex=temp(randorder);

%% Retrieve actual epochID
epochID = selectID(randomindex);
end

