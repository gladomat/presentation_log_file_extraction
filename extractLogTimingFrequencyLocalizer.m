% This script extracts the timing of stimulus presentations relative to the
% first timepoint. It finds the time of the played sounds, gets the unique
% entries from the played sounds and cleans the timing variable of the
% repeated sounds. Use it on the 6 runs of the frequency localizer only.
% Paul Glad Mihai, CC-BY-04 2017, mihai@cbs.mpg.de

clear

sub = {
%     '01'
%     '02'
%     '03'
%     '04'
%     '05'
%     '06'
%     '08'
%     '09'
%     '10'
%     '11'
%     '12'
%     '13'
%     '14'
%     '15'
%     '16'
%     '18'
%     '19'
%     '20'
%     '21'
%     '22'
%     '24'
%     '26'
%     '28'
%     '29'
%     '30'
%     '31'
%     '32'
%     '33'
%      '35'
%     '39'
%    '40'
    '41'
%     '43'
    };

fileName = {
    '-localiser_56sounds_run-01.log'
    '-localiser_56sounds_run-02.log'
    '-localiser_56sounds_run-03.log'
    '-localiser_56sounds_run-04.log'
    '-localiser_56sounds_run-05.log'
    '-localiser_56sounds_run-06.log'
    };

% You could also pick the files manually.
% [fileName,fileFolderPath,~] = uigetfile('*.log','Select log file','MultiSelect','off');

% Output directory up to subject code name.
outDir = '/nobackup/alster2/Glad/Projects/Top-down_mod_MGB/Experiments/TdMGB_fMRI/DATA/sourcedata/';
% The rest of the output directory after subject code name.
outDirEnd = '/ses-localizer/func/';
% Directory of log files.
mainDir = '/nobackup/alster2/Glad/Projects/Top-down_mod_MGB/Experiments/TdMGB_fMRI/DATA/presentation/TDMGB_freq_localizer/';

for iSub = 1:numel(sub)
    for iRun = 1:numel(fileName)
        
        fprintf('Running subject %s run %02i.', sub{iSub}, iRun);
        
        fullFilePath = [mainDir, sub{iSub}, fileName{iRun}];
        [dataName, data] = importPresentationLog(fullFilePath);
        
        % Set start time at zero
        data.time = (data.time - data.time(1))/10000;
        % Find time of played sounds
        timeOfSound = data.time(strcmp(data.event_type, 'Sound'));
        
        %% Find repetitions and remove them.
        code = data.code(strcmp(data.event_type, 'Sound'));
        % First find null events and remove them.
        nulls = find(contains(code,'nu'));
        code(nulls) = [];
        timeOfSound(nulls) = [];
        [~, idx1, idx2] = unique(code, 'stable');  % Get indices of unique entries. Stable returns original order of list.
        timeOfSound = timeOfSound(idx1);
        
        % Create cell arrays for SPM and save as .mat file.
        names = {'sound'};
        onsets = {timeOfSound};
        durations = {ones(length(timeOfSound), 1)};
        fullOutDir = [outDir, 'sub-', sub{iSub}, outDirEnd];
        outName = sprintf('%s/sub-%s_task-localizer_run-%02i_conditions.mat', fullOutDir, sub{iSub}, iRun);
        save(outName,'names','durations','onsets')
        
        % Create a table and save it as a tab-delimited file.
        onset = timeOfSound;
        duration = ones(length(timeOfSound), 1);
        trial_type = repmat('sound', length(timeOfSound), 1);
        sound_event = code(sort(idx1));
        T = table(onset, duration, trial_type, sound_event);
        outName = sprintf('%s/sub-%s_task-localizer_run-%02i_events.tsv', fullOutDir, sub{iSub}, iRun);
        writetable(T,outName,'Delimiter','\t','FileType', 'text')
    end
end