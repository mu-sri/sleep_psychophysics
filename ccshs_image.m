% Read in the constants defined
ccshs_image_init

%% Reading ccshs edf data and create .jpg images
currentdir = pwd;

% blockEdfLoad directory
addpath(genpath(BLOCKEDFLOAD_DIR))

% CCSHS directory
datadir = CCSHS_DIR;

ccshs_data = dir(strcat([datadir,'*.edf']));

% Number of datasets
num_data = length(ccshs_data);

%% Reading EDF using blockEdfLoad 
% https://sleepdata.org/community/tools/dennisdean-block-edf-loader
for n = 2:5
% n=1; % Change into for loop when 1 subject code is done
cd(datadir)
edfFile = ccshs_data(n).name;
[header,signalHeader,signalCell] = blockEdfLoad(edfFile);

% Reading filename to obtain subjectID
subjectID = str2num(edfFile(16:18));

%% Initialise figure and folder 
cd(currentdir)
foldername = strcat('ccshs_1800',num2str(subjectID,'%03d'),'_1EEG');
mkdir(foldername);
cd(foldername)

%% Channel derivation for scoring (perform once per subjectID)
% According to CCSHS manual (Derive manually)
% Can be change according to the PSG scoring criteria

selectedSignal{1} = signalCell{1}-signalCell{4};
selectedHeader(1).signal_labels = 'C3-A2';
selectedHeader(1).signal_type = 'EEG';
selectedHeader(1).sampling_rate = signalHeader(1).samples_in_record;

% selectedSignal{2} = signalCell{2}-signalCell{3};
% selectedHeader(2).signal_labels = 'C4-A1';
% selectedHeader(2).signal_type = 'EEG';
% selectedHeader(2).sampling_rate = signalHeader(2).samples_in_record;
% 
% selectedSignal{3} = signalCell{5}-signalCell{4};
% selectedHeader(3).signal_labels = 'LOC-A2';
% selectedHeader(3).signal_type = 'EOG';
% selectedHeader(3).sampling_rate = signalHeader(5).samples_in_record;
% 
% selectedSignal{4} = signalCell{6}-signalCell{3};
% selectedHeader(4).signal_labels = 'ROC-A1';
% selectedHeader(4).signal_type = 'EOG';
% selectedHeader(4).sampling_rate = signalHeader(6).samples_in_record;
% 
% selectedSignal{5} = signalCell{13}-signalCell{14};
% selectedHeader(5).signal_labels = 'EMG1-EMG2';
% selectedHeader(5).signal_type = 'EMG';
% selectedHeader(5).sampling_rate = signalHeader(13).samples_in_record;
% 
% selectedSignal{6} = signalCell{8};
% selectedHeader(6).signal_labels = 'ECG';
% selectedHeader(6).signal_type = 'ECG';
% selectedHeader(6).sampling_rate = signalHeader(8).samples_in_record;
% 
% selectedSignal{7} = signalCell{16};
% selectedHeader(7).signal_labels = 'AIRFLOW';
% selectedHeader(7).signal_type = 'Respiratory';
% selectedHeader(7).sampling_rate = signalHeader(16).samples_in_record;
% 
% selectedSignal{8} = signalCell{17};
% selectedHeader(8).signal_labels = signalHeader(17).signal_labels; % THOR EFFORT
% selectedHeader(8).signal_type = signalHeader(17).tranducer_type;
% selectedHeader(8).sampling_rate = signalHeader(17).samples_in_record;
% 
% selectedSignal{9} = signalCell{18};
% selectedHeader(9).signal_labels = signalHeader(18).signal_labels; % THOR EFFORT
% selectedHeader(9).signal_type = signalHeader(18).tranducer_type;
% selectedHeader(9).sampling_rate = signalHeader(18).samples_in_record;
% 
% selectedSignal{10} = signalCell{22};
% selectedHeader(10).signal_labels = signalHeader(22).signal_labels; % OX STATUS
% selectedHeader(10).signal_type = signalHeader(22).tranducer_type;
% selectedHeader(10).sampling_rate = signalHeader(22).samples_in_record;
% 
% selectedSignal{11} = signalCell{24};
% selectedHeader(11).signal_labels = signalHeader(24).signal_labels; % THOR EFFORT
% selectedHeader(11).signal_type = signalHeader(24).tranducer_type;
% selectedHeader(11).sampling_rate = signalHeader(24).samples_in_record;

% ******* Loop for derivation of channels ******** 
% Use when all included channels are finalised (Easier to manipulate with
% code above + for unknown number of channels)
% Will be different for SHHS dataset
% all_labels = {'C3-A2','C4-A1','LOC-A2','ROC-A1','EMG1-EMG2','ECG','AIRFLOW'};
% all_type = {'EEG','EEG','EOG','EOG','EMG','ECG','Respiratory'};
% first_channel = [1,2,5,6,13,8,16,17,18,22,24];
% second_channel = [4,3,4,3,14,0,0,0,0,0,0];
% for s = 1:num_signal
%     if second_channel(s)~=0 % If bipolar ref required
%         selectedSignal{s} = signalCell{first_channel(s)}-signalCell{second_channel(s)};
%         selectedHeader(s).signal_labels = all_labels{s};
%         selectedHeader(s).signal_type = all_type{s};
%         selectedHeader(s).sampling_rate = signalHeader(first_channel(s)).samples_in_record;
%     else
%         selectedSignal{s} = signalCell{first_channel(s)};
%         selectedHeader(s).signal_labels = signalHeader(first_channel(s)).signal_labels; % THOR EFFORT
%         selectedHeader(s).signal_type = signalHeader(first_channel(s)).tranducer_type;
%         selectedHeader(s).sampling_rate = signalHeader(first_channel(s)).samples_in_record;
%     end
% end       
% ************************************************

% Get number of signals
num_signals = length(selectedSignal);
%% Create and save images of PSG
% Adapted from: https://sleepdata.org/community/tools/dennisdean-block-edf-loader

% Number of time segments
%   To set for loop for saving images
record_duration = header.num_data_records; % Record duration (sec) 
tmax = 30;
num_segment = ceil(record_duration/tmax);


%% 
%% Add each signal to figure
for timeID = 1:num_segment
%% One timeID 
% timeID = 1;
% Set end time of each time segment
% tstart = (timeID-1)*30; % Index of time is discrete but time(sec) is
% not.

figure;
for s = 1:num_signals
    % Get signal
    signal =  selectedSignal{s};
    samplingRate = selectedHeader(s).sampling_rate; % Sampling rate of the channel (Different parameters have different sampling rate
    t = [0:length(signal)-1]/samplingRate; % = record_duration

    % Parameters for normalisation - use global max and min if amplitude
    % matters
    sigMin = -0.25; % min(signal);
    sigMax =  0.25; % max(signal);
%     signalRange = sigMax - sigMin;
%     
    % Identify indexes of 30 seconds of signal according to tstart, tend
    % Otherwise, indexes = find(t<=tmax);
    tStart = find(t==(timeID-1)*30);
    tEnd = find(t==timeID*30);
    indexes = tStart:1:tEnd;
    signal = signal(indexes);
    time = t(1:length(indexes)); % time = t(indexes); % Hide real time 
    % time = t(find(t<=tmax));

%     %% 60-Hz notch filter
%     w0 = 60/(samplingRate/2);
%     bw = w0/35;
%     [b,a] = iirnotch(w0,bw);
%     signal = filter(b,a,signal);
%     
%     %% Low-pass filter
%     wn = 10/(samplingRate/2);
%     n_order = 1;
%     [b,a] = butter(n_order,wn);
%     signal = filter(b,a,signal);
    %%
    % Normalize signal
%     sigMin = min(signal);
%     sigMax = max(signal);
%     signalRange = sigMax - sigMin;
% 
%      signal = (signal - sigMin); % Normalised to 0
%      if signalRange~= 0
%         signal = signal/(sigMax-sigMin);
%      end
%     
%     % Add signal below the previous one
% %     signal = signal + (num_signals - s + 1);
%     signal = signal - 0.5*mean(signal) + (num_signals - s + 1);

    % Color code signal type - can be customised + will depends on screen setting
    switch (selectedHeader(s).signal_type)
        case 'EEG'
            ccode = [0.1,0.3,0.8];
        case 'EOG'
            ccode = [0.1,0.5,0.3];
        case 'EMG'
            ccode = [0.7,0.4,0.1];
        case 'ECG'
            ccode = [0.8,0.1,0.2];
        otherwise
            ccode = [0.2,0.2,0.2];
    end
    % Plot signal
    plot(time, signal,'k');
    hold on
end
%%
grid on

% Set axis limits -?? default?
% v = axis();
% v(1:2) = [0 tmax];
% v(3:4) = [-0.5 num_signals+1];
% axis(v);

% Set x axis
xlabel('Time(sec)');
ax = gca;
ax.XTick = [0:30];
ax.FontSize = 20;


% Set y axis labels
% signalLabels = cell(1,num_signals); %Revert the order such that first channel stays on top
% for s = 1:num_signals
%     signalLabels{num_signals-s+1} = selectedHeader(s).signal_labels;
% end
% ax.YTick = 1:num_signals;
% ax.YTickLabels = signalLabels;
% ax.FontSize = 15;
ylabel('Amplitude (mV)')
% ax.YTick = linspace(sigMin,sigMax,30);
axis([0 30 sigMin sigMax])

% Set figure size
fig = gcf;
fig.Units = 'points';
fig.Position = [0, 10, 1450, 350]; % ***** New sizeSize of object images; ratio ok??

% fig.Position = [10,10,2048,683]; %% reduce size
fig.Color = [0.95 0.95 0.95];
% set(gcf,'Units','Normalized','OuterPosition',[0,0.04,1,0.96]) % Fullscreen figure


%% Save figure as PNG image
imagename = strcat('ccshs_',num2str(subjectID,'%03d'),'_',num2str(timeID,'%04d'),'.png');
saveas(gcf,imagename) % saveas, imwrite or imsave?

close
end % end/timeID

cd(currentdir)

end %end/ subjectID