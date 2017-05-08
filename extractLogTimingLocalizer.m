% This script extracts the timing of stimulus presentations relative to the
% first timepoint. It finds the time of the played sounds, gets the unique
% entries from the played sounds and cleans the timing variable of the
% repeated sounds.
clear

sub = {
    '02'
    '05'
    '08'
    '10'
    '15'
    '19'
    '21'
    '24'
    '01'
    '03'
    '04'
    '06'
    '09'
    '11'
    '12'
    '13'
    '14'
    '16'
    '18'
    '20'
    '22'
    '26'
    '28'
    '29'
    '30'
    '32'
    '31'
    '33'
    '35'
    '37'
    '39'
    '40'
    '41'
    '43'
    };

fileName = {
    '-localiser.log'
    };

% You could also pick the files manually.
% [fileName,fileFolderPath,~] = uigetfile('*.log','Select log file','MultiSelect','off');

% Output directory up to subject code name.
outDir = '/nobackup/alster2/Glad/Projects/Top-down_mod_MGB/Experiments/TdMGB_fMRI/DATA/sourcedata/';
% The rest of the output directory after subject code name.
outDirEnd = '/ses-spespk/func/';
% Directory of log files.
mainDir = '/nobackup/alster2/Glad/Projects/Top-down_mod_MGB/Experiments/TdMGB_fMRI/DATA/presentation/';



for iSub = 1:numel(sub)
    for iRun = 1:numel(fileName)
        fprintf('Running sub %s run %s.\n', sub{iSub}, fileName{iRun});
        
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
        outName = sprintf('%s/sub-%s_task-spespk_run-localizer_conditions.mat', fullOutDir, sub{iSub});
        save(outName,'names','durations','onsets')
        
        % Create a table and save it as a tab-delimited file.
        onset = timeOfSound;
        duration = ones(length(timeOfSound), 1);
        trial_type = repmat('sound', length(timeOfSound), 1);
        sound_event = code(sort(idx1));
        T = table(onset, duration, trial_type, sound_event);
        outName = sprintf('%s/sub-%s_task-spespk_run-localizer_events.tsv', fullOutDir, sub{iSub});
        writetable(T,outName,'Delimiter','\t','FileType', 'text')
    end
end