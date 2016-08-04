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
    };

fileName = {
    '-localiser.log'
    };

% You could also pick the files manually.
% [fileName,fileFolderPath,~] = uigetfile('*.log','Select log file','MultiSelect','off');

% Output directory up to subject code name.
outDir = '/scr/archimedes1/Glad/Projects/Top-down_mod_MGB/Experiments/TdMGB_fMRI/DATA/sourcedata/';
% The rest of the output directory after subject code name.
outDirEnd = '/ses-spespk/func/';
% Directory of log files.
mainDir = '/scr/archimedes1/Glad/Projects/Top-down_mod_MGB/Experiments/TdMGB_fMRI/DATA/presentation/';



for iSub = 1:numel(sub)
    for iRun = 1:numel(fileName)
        
        fullFilePath = [mainDir, sub{iSub}, fileName{iRun}];
        [dataName, data] = importPresentationLog(fullFilePath);
        
        % Set start time at zero
        data.time = (data.time - data.time(1))/10000;
        % Find time of played sounds
        timeOfSound = data.time(strcmp(data.event_type, 'Sound'));
        
        %% Find repetitions and remove them.
        code = data.code(strcmp(data.event_type, 'Sound'));
        [~, idx1, idx2] = unique(code);  % Get indices of unique entries.
        timeOfSound = sort(timeOfSound(idx1));
        
        % Create cell arrays for SPM and save as .mat file.
        names = {'sound'};
        onsets = {timeOfSound};
        durations = {ones(length(timeOfSound), 1)};
        fullOutDir = [outDir, 'sub-', sub{iSub}, outDirEnd];
        outName = sprintf('%s/sub-%s_task-localizer_conditions.mat', fullOutDir, sub{iSub});
        save(outName,'names','durations','onsets')
        
        % Create a table and save it as a tab-delimited file.
        onset = timeOfSound;
        duration = ones(length(timeOfSound), 1);
        trial_type = repmat('sound', length(timeOfSound), 1);
        sound_event = code(sort(idx1));
        T = table(onset, duration, trial_type, sound_event);
        outName = sprintf('%s/sub-%s_task-localizer_events.tsv', fullOutDir, sub{iSub});
        writetable(T,outName,'Delimiter','\t','FileType', 'text')
    end
end


%         % I thought this here is necessary, but it isn't, as unique works.
%         % Another way is necessary to remove the repetitions, as the
%         % function unique sorts the entries before deciding upon
%         % uniqueness, thus removing the information of what was first
%         % presented.
%         char_code = char(code);
%         % Find consecutive repetitions by comparing strings. If all five
%         % strings are found to be equal, then that is the repetition (since
%         % a total of five strings represent the name).
%         numOfStrings = sum(char_code(1:end-1,:) == char_code(2:end,:), 2);
%         % +1 since it takes the first entry found, and we want the second.
%         repStrings = find(numOfStrings == 5) + 1;
%         timeOfSound(repStrings) = [];  % Remove undesired entries.