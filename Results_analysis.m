%% Psychophysics analysis

clear result
clearvars

Results_analysis_init;
 
 %% Load result file and annotation file
load(PARTICIPANT_RESPONSE_FILE)
load(ANSWER_FILE)

conflevel_accuracy = zeros(4, 2);


%% Accuracy
for i=1:length(trial)
    index(i) = trial(i).fileID;
    % Change scored stage [0,1,2,3,5] to [1,2,3,4,5]
    if sleepstage(index(i))<5
        correctstage(i) = sleepstage(index(i))+1;
    else
        correctstage(i) = sleepstage(index(i));
    end
    
    % Check the response
    score(i) = (trial(i).response==correctstage(i));
    response(i)=trial(i).response;
    
    conflvl = 5 - trial(i).confidence; % Reverse the confidence level %
    conflevel_accuracy(conflvl, (score(i) == 1) + 1) = conflevel_accuracy(conflvl, (score(i) == 1) + 1) + 1;
end
accuracy = sum(score==1)/length(trial) *100;
total_response_by_conflevel = conflevel_accuracy(:,1) + conflevel_accuracy(:,2);
conflevel_accuracy_percentage = (conflevel_accuracy(:,2)./total_response_by_conflevel)*100;

%% Confidence level
% Initialise counter of each level
counter = zeros(4,1);
% result = struct;
% for c=1:4
%     result(c).count =0;
% end

% Prepare data for metacogntion analysis
for i=1:length(trial)
    for c =1:4 % Confidence level
        if trial(i).confidence == c
            counter(c)=counter(c)+1;
            result(c).count = counter(c); % Increment number of epochs

            % result(c).count = result(c).count + 1; % Increment number result(c).countof epochs
            result(c).ID(counter(c)) = i;   % Record epoch ID
            result(c).response(counter(c)) = trial(i).response; % Record response
            result(c).labelled(counter(c)) = sleepstage(trial(i).fileID); % Record actual stage
            result(c).score(counter(c)) = (trial(i).response == correctstage(i)); % Record score (0/1)
        end
    end
end

%% Flip confidence level
% When recording the response, 1 = most confidence --> can change this in
% runExp (later)
% Key: 4 - Most confident, 1 - not sure
temp = result;

for c=1:4
    temp(5-c) = result(c);
end
result = temp;

%% ******** Visualise result *********
% Can combine loops for efficiency (later)
%% Fig.1 Counts/level
confidenceX = 1:4;
for c=1:4
    confidenceFreq(c) = result(c).count;
end
figure;
bar(confidenceX,confidenceFreq)
xlabel('Confidence')
ylabel('Count')

%% Fig. 2 Correct/level
for c=1:4
    correctFreq(c) = sum(result(c).score==1);
end
figure;
bar(confidenceX,correctFreq)
xlabel('Confidence')
ylabel('Correct count')

%% Fig.3 %Correct/level
perCorrect = correctFreq./confidenceFreq *100;
figure;
bar(confidenceX,perCorrect)
xlabel('Confidence')
ylabel('Correct (%)')


%% Fig.4 Response/confidence level
% 
stageLabel = {'W','N1','N2','N3','R'};
stageID = [0,1,2,3,5];

for c=1:4
    for s=1:5
       stageCntLvl(c,s) = sum(result(c).response==s);
    end
end
figure; 
bar(stageCntLvl,'stacked')
legend(stageLabel)
xlabel('Confidence')
ylabel('Response Count')

%% Fig.5 Actual stage/confidence level
for c=1:4
    for s=1:5
       scoredCntLvl(c,s) = sum(result(c).labelled==stageID(s));
    end
end
figure; 
bar(scoredCntLvl,'stacked')
legend(stageLabel)
ylabel('Correct count')
%% Fig.6 % Correct/level with sleep stages ??
% Counting correct stage
for c=1:4
    correctid = find(result(c).score);
    stagecount = result(c).response(correctid);
    for s=1:5
       stageCorrect(c,s) = sum(stagecount==s);
    end
end

% Convert to percentage
perstageCorrect = stageCorrect./repmat(confidenceFreq',1,5);

figure; 
bar(stageCorrect,'stacked')
legend(stageLabel)
xlabel('Confidence')
ylabel('Correct (%)')

%% Fig. 7 Hyponogram with sampled epochs
figure;
plot(sleepstage)
hold on
plot(index,stageID(response),'*')
hold off

%% Fig. 8 Confusion matrix
% Confusion matrix
confmat = zeros(5,5);
for i = 1:length(response)
    confmat(correctstage(i),response(i)) = confmat(correctstage(i),response(i))+1;
%     for r = 1:5
%         for a = 1:5
%             if (response(i)== stage(r)) && (correctstage(i)==stage(a))
%                 confmat(a,r)=confmat(a,r)+1;
%             end
%         end
%     end
end

% Change to percentage
totalTarget = sum(confmat,2);
perResponse = confmat./repmat(totalTarget,1,5)*100;

% Prepare the labels for image cells
t = strings(5,5);
for i=1:5
    for j=1:5
        t(i,j) = compose(strcat(num2str(confmat(i,j)),'\n', ...
            num2str(round(perResponse(i,j), 2)),'%'));
    end
end

%% Confusion matrix heat map (%)
figure;
imagesc(perResponse);
title(strcat('Confusion Matrix - No: ', subj.number, ' Initial: ', subj.initials, ' Level:', subj.level));
x = repmat(1:5,5,1);
y = x';
text(x(:), y(:), cellstr(t), 'HorizontalAlignment', 'Center', 'FontSize', 12, ...
    'FontWeight', 'bold');
ax = gca;
ax.XTick = 1:5;
ax.YTick = 1:5;
ax.XTickLabels = {'W','N1','N2','N3','R'};
ax.YTickLabels = {'W','N1','N2','N3','R'};
ylabel('Target')
xlabel('Response')
ax.XAxisLocation = 'top';

%Define colormap
c1=[0 0.65 0]; %G
c2=[1 1 0]; %Y
c3=[1 0 0]; %R
n1=20;
n2=20;
cmap=[linspace(c1(1),c2(1),n1);linspace(c1(2),c2(2),n1);linspace(c1(3),c2(3),n1)];
cmap(:,end+1:end+n2)=[linspace(c2(1),c3(1),n2);linspace(c2(2),c3(2),n2);linspace(c2(3),c3(3),n2)];
colormap(cmap')
h = colorbar
set(h, 'ylim', [0 100])


%% Conditional accuracy
figure;
x = 1:4;
y=conflevel_accuracy_percentage;
bar(x,y);
title(strcat('Conditional accuracy - No: ', subj.number, ' Initial: ', subj.initials, ' Level:', subj.level));
ax = gca;
ax.XTickLabels = 1:4;
ylabel('Percentage correct (%)')
ylim([0, 100]);
xlabel('Confidence level')
text(1:length(conflevel_accuracy_percentage),conflevel_accuracy_percentage,strcat(num2str(round(conflevel_accuracy_percentage(:), 2)), '%'),'vert','bottom','horiz','center');

% Draw a line through 20%
xlim=get(gca,'xlim');
hold on;
plot(xlim, [20 20]);

%% Confusion matrix - MATLAB + Ben's
% addpath(genpath('/Users/sleeping/Documents/MATLAB/unsup_sleep_staging/HCTSA'))
% 
% % Confusion matrix of train data
% 
% % Labelled - make non-zero stage
% g_labelTrain = label(trainTS)+1;
% 
% % Clustered - Use final clustering output
% g_clustTrain = equi_train+1;
% 
% % Cluster 6 becomes 5
% g_labelTrain(g_labelTrain==6) = 5;
% g_clustTrain(g_clustTrain==6) = 5;
% 
% % BINARY TO CLASS FUNCTION FROM BEN'S HCTSA
% labelTrainBF= BF_ToBinaryClass(g_labelTrain,nclust);
% clustTrainBF = BF_ToBinaryClass(g_clustTrain,nclust);
% 
% 
% % Visualise confusion matrix
% figure;
% plotconfusion(labelTrainBF,clustTrainBF)
% 
% % Plot setting
% ax = gca;
% ax.XTickLabel(1:nclust)=stgID.useStgName;
% ax.YTickLabel(1:nclust)=stgID.useStgName;
% 
% 
% %% Confusion matrix of test data
% % Labelled - make non-zero stage  
% g_labelTest = label(testTS)+1;
% 
% % Clustered - Use final clustering output
% g_clustTest = equi_test+1;
% 
% % Cluster 6 becomes 5
% g_labelTest(g_labelTest==6) = 5;
% g_clustTest(g_clustTest==6) = 5;
% 
% % BINARY TO CLASS FUNCTION FROM BEN'S HCTSA
% labelTestBF= BF_ToBinaryClass(g_labelTest,nclust);
% clustTestBF = BF_ToBinaryClass(g_clustTest,nclust);
% 
% 
% % Visualise confusion matrix
% figure;
% plotconfusion(labelTestBF,clustTestBF)
% 
% % Plot setting
% ax = gca;
% ax.XTickLabel(1:nclust)=stgID.useStgName;
% ax.YTickLabel(1:nclust)=stgID.useStgName;